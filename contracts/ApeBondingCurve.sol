// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ApeFormula} from "./ApeFormula.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IApeCurveFactory} from "./interfaces/IApeCurveFactory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ApeBondingCurve is ApeFormula, ReentrancyGuard {
    IERC20 public immutable tokenContract;

    uint256 public ethReserve;

    uint256 public swapFeePercentage;

    uint256 public immutable ETH_AMOUNT_FOR_LIQUIDITY;
    uint256 public immutable ETH_AMOUNT_FOR_LIQUIDITY_FEE;
    uint256 public immutable ETH_AMOUNT_FOR_DEV_REWARD;
    uint256 public immutable TOTAL_ETH_TO_COMPLETE_CURVE;

    address public immutable TOKEN_DEVELOPER;

    IUniswapV2Router02 public uniswapRouter;
    IApeCurveFactory public factoryContract;
    bool public isActive = true;

    address public immutable TOKEN_DEV;

    event LogBuy(uint256 indexed amountBought, uint256 indexed totalCost, address indexed buyer);
    event LogSell(uint256 indexed amountSell, uint256 indexed reward, address indexed seller);
    event BondingCurveComplete(address indexed tokenAddress, address indexed liquidityPoolAddress);

    constructor(
        address _tokenDeveloper,
        address _tokenAddress,
        uint256 _swapFeePercentage,
        uint256 _ethAmountForLiquidity,
        uint256 _ethAmountForLiquidityFee,
        uint256 _ethAmountForDevReward,
        uint256 _tokenSupplyToSell,
        address _uniswapRouter,
        uint256 _reserveRatio
    )
        ApeFormula(
            _reserveRatio,
            _ethAmountForLiquidity + _ethAmountForLiquidityFee + _ethAmountForDevReward,
            _tokenSupplyToSell
        )
    {
        TOKEN_DEVELOPER = _tokenDeveloper;
        tokenContract = IERC20(_tokenAddress);

        swapFeePercentage = _swapFeePercentage;

        ETH_AMOUNT_FOR_LIQUIDITY = _ethAmountForLiquidity;
        ETH_AMOUNT_FOR_LIQUIDITY_FEE = _ethAmountForLiquidityFee;
        ETH_AMOUNT_FOR_DEV_REWARD = _ethAmountForDevReward;

        TOTAL_ETH_TO_COMPLETE_CURVE =
            ETH_AMOUNT_FOR_LIQUIDITY + ETH_AMOUNT_FOR_LIQUIDITY_FEE + ETH_AMOUNT_FOR_DEV_REWARD;

        factoryContract = IApeCurveFactory(msg.sender);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);

        // reserveRatio = _reserveRatio;
    }

    function getCirculatingSupply() public view returns (uint256) {
        uint256 totalSupply = tokenContract.totalSupply();
        uint256 balanceOfBondingCurve = tokenContract.balanceOf(address(this));
        return totalSupply - balanceOfBondingCurve;
    }

    function _deActivateBondingCurve() internal {
        isActive = false;
    }

    function buyFor(address buyer) internal returns (bool) {
        require(isActive, "bonding curve must be active");
        require(msg.value > 0);

        uint256 buyFee = _extractBuyFees(msg.value);
        uint256 effectiveEth = msg.value - buyFee;
        uint256 refund = 0;
        bool bondingCurveComplete = false;

        uint256 requiredEthToCompleteCurve = remainingEthToCompleteCurve();

        if (effectiveEth > requiredEthToCompleteCurve) {
            effectiveEth = requiredEthToCompleteCurve;
            buyFee = _calculateFees(requiredEthToCompleteCurve);
            refund = msg.value - effectiveEth - buyFee;
        }

        if (effectiveEth >= requiredEthToCompleteCurve) {
            bondingCurveComplete = true;
            _deactivateBondingCurve();
        }

        uint256 currentCirculatingSupply = getCirculatingSupply();

        uint256 tokensToTransfer = calculatePurchaseReturn(currentCirculatingSupply, ethReserve, effectiveEth);

        ethReserve += effectiveEth;

        require(tokenContract.transfer(buyer, tokensToTransfer), "ERC20 transfer failed");

        address feeRecipient = factoryContract.feeRecipient();
        payable(feeRecipient).transfer(buyFee);

        if (refund > 0) {
            payable(buyer).transfer(refund);
        }

        emit LogBuy(tokensToTransfer, effectiveEth + buyFee, buyer);

        if (bondingCurveComplete) {
            _completeBondingCurve();
            payable(TOKEN_DEVELOPER).transfer(ETH_AMOUNT_FOR_DEV_REWARD);
            payable(factoryContract.feeRecipient()).transfer(ETH_AMOUNT_FOR_LIQUIDITY_FEE);
        }
        return true;
    }

    function buy(address buyer) public payable nonReentrant returns (bool) {
        require(msg.sender == address(factoryContract), "You are not factory");
        return buyFor(buyer);
    }

    function buy() public payable nonReentrant returns (bool) {
        return buyFor(msg.sender);
    }

    function sell(uint256 tokenAmount) public nonReentrant returns (bool) {
        require(isActive, "bonding curve must be active");
        require(tokenAmount > 0);

        uint256 currentCirculatingSupply = getCirculatingSupply();

        uint256 ethAmount = calculateSaleReturn(currentCirculatingSupply, ethReserve, tokenAmount);

        require(ethAmount <= ethReserve, "Bonding curve does not have sufficient funds");

        uint256 sellFee = _calculateFees(ethAmount);
        uint256 effectiveEthAmount = ethAmount - sellFee;

        ethReserve -= ethAmount;

        payable(msg.sender).transfer(effectiveEthAmount);

        require(tokenContract.transferFrom(msg.sender, address(this), tokenAmount));

        // Transfer fees to the fee recipient
        address feeTo = factoryContract.feeRecipient();
        payable(feeTo).transfer(sellFee);

        emit LogSell(tokenAmount, ethAmount, msg.sender);
        return true;
    }

    function _completeBondingCurve() internal {
        uint256 ethAmountToSendLP = ETH_AMOUNT_FOR_LIQUIDITY;
        uint256 tokenAmountToSendLP = tokenContract.balanceOf(address(this));

        require(tokenContract.approve(address(uniswapRouter), tokenAmountToSendLP), "Approve failed");
        require(address(this).balance >= ethAmountToSendLP, "Insufficient ETH balance");

        uniswapRouter.addLiquidityETH{value: ethAmountToSendLP}(
            address(tokenContract), tokenAmountToSendLP, 0, 0, address(this), block.timestamp
        );

        // Burn the LP tokens
        address WETH = uniswapRouter.WETH();
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapRouter.factory());
        IERC20 lpToken = IERC20(uniswapV2Factory.getPair(WETH, address(tokenContract)));

        bool success = lpToken.transfer(address(0), lpToken.balanceOf(address(this)));
        require(success, "Liquidity Pool burning failed");

        emit BondingCurveComplete(address(tokenContract), address(lpToken));
    }

    function _extractBuyFees(uint256 amount) internal view returns (uint256) {
        return (amount * swapFeePercentage) / (100 + swapFeePercentage);
    }

    function _calculateFees(uint256 amount) internal view returns (uint256) {
        return (amount * swapFeePercentage) / 100;
    }

    function _deactivateBondingCurve() internal {
        isActive = false;
    }

    function remainingEthToCompleteCurve() public view returns (uint256) {
        return TOTAL_ETH_TO_COMPLETE_CURVE - ethReserve;
    }
}