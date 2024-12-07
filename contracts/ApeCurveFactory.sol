// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ERC20FixedSupply} from "./ERC20FixedSupply.sol";
import {ApeBondingCurve} from "./ApeBondingCurve.sol";

contract ApeCurveFactory is Ownable {
    mapping(address => address) public getTokenBondingCurve;
    mapping(address => uint256) public getReserveRatio;
    address[] public allTokenAddresses;

    uint256 public tokenTotalSupply;
    address public feeRecipient;
    address public feeRecipientSetter;

    uint256 public swapFeePercentage;

    uint256 public ethAmountForLiquidity;
    uint256 public ethAmountForLiquidityFee;
    uint256 public ethAmountForDevReward;

    uint256 public tokenSupplyToSell;

    address public uniswapV2RouterAddress;

    uint256 public standardReserveRatio;

    event TokenCreated(
        address indexed token,
        address indexed bondingCurve,
        uint256 reserveRatio
    );
    event SwapFeePercentageUpdated(uint256 newPercentage);

    constructor(
        uint256 _tokenTotalSupply,
        uint256 _tokenSupplyToSell,
        uint256 _swapFeePercentage,
        uint256 _ethAmountForLiquidity,
        uint256 _ethAmountForLiquidityFee,
        uint256 _ethAmountForDevReward,
        address _uniswapV2RouterAddress,
        address _feeRecipient,
        address _feeRecipientSetter,
        uint256 _standardReserveRatio
    ) Ownable(msg.sender) {
        tokenTotalSupply = _tokenTotalSupply;
        tokenSupplyToSell = _tokenSupplyToSell;
        swapFeePercentage = _swapFeePercentage;

        ethAmountForLiquidity = _ethAmountForLiquidity;
        ethAmountForLiquidityFee = _ethAmountForLiquidityFee;
        ethAmountForDevReward = _ethAmountForDevReward;

        uniswapV2RouterAddress = _uniswapV2RouterAddress;

        feeRecipientSetter = _feeRecipientSetter;
        feeRecipient = _feeRecipient;

        standardReserveRatio = _standardReserveRatio;
    }


    /// @notice Returns the total number of tokens created by this factory
    /// @return The length of the allTokenAddresses array
    function allTokensLength() external view returns (uint256) {
        return allTokenAddresses.length;
    }

    function createToken(
        string memory name,
        string memory symbol,
        string memory tokenURI
    ) external payable returns (address) {
        ERC20FixedSupply token = new ERC20FixedSupply(
            name,
            symbol,
            tokenTotalSupply,
            tokenURI
        );

        ApeBondingCurve bondingCurve = new ApeBondingCurve(
            address(msg.sender),
            address(token),
            swapFeePercentage,
            ethAmountForLiquidity,
            ethAmountForLiquidityFee,
            ethAmountForDevReward,
            tokenSupplyToSell,
            uniswapV2RouterAddress,
            standardReserveRatio
        );

        require(
            token.transfer(address(bondingCurve), token.totalSupply()),
            "ERC20 transfer failed"
        );

        getTokenBondingCurve[address(token)] = address(bondingCurve);
        getReserveRatio[address(bondingCurve)] = standardReserveRatio;
        allTokenAddresses.push(address(token));

        emit TokenCreated(
            address(token),
            address(bondingCurve),
            standardReserveRatio
        );

        if (msg.value > 0) {
            bondingCurve.buy{value: msg.value}(msg.sender);
        }
        return address(token);
    }

    function setFeeRecipientSetter(address _feeRecipientSetter) external {
        require(msg.sender == feeRecipientSetter, "PUMPV1: FORBIDDEN");
        feeRecipientSetter = _feeRecipientSetter;
    }

    function setFeeRecipient(address _feeRecipient) external {
        require(msg.sender == feeRecipientSetter, "PUMPV1: FORBIDDEN");
        feeRecipient = _feeRecipient;
    }

    function setUniswapRouterAddress(
        address _uniswapV2RouterAddress
    ) external onlyOwner {
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
    }

    function setBondingCurveVariables(
        uint256 _tokenTotalSupply,
        uint256 _ethAmountForLiquidity,
        uint256 _ethAmountForLiquidityFee,
        uint256 _ethAmountForDevReward,
        uint256 _standardReserveRatio
    ) external onlyOwner {
        tokenTotalSupply =  _tokenTotalSupply;
        ethAmountForLiquidity =  _ethAmountForLiquidity;
        ethAmountForLiquidityFee =  _ethAmountForLiquidityFee;
        ethAmountForDevReward =  _ethAmountForDevReward;
        standardReserveRatio =  _standardReserveRatio;    
    }
}
