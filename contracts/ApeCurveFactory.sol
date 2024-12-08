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
    address public uniswapV2RouterAddress;

    event TokenCreated(
        address indexed token,
        address indexed bondingCurve,
        uint256 reserveRatio
    );
    event SwapFeePercentageUpdated(uint256 newPercentage);

    constructor(
        uint256 _tokenTotalSupply,
        uint256 _swapFeePercentage,
        address _uniswapV2RouterAddress,
        address _feeRecipient,
        address _feeRecipientSetter
    ) Ownable(msg.sender) {
        tokenTotalSupply = _tokenTotalSupply;
        swapFeePercentage = _swapFeePercentage;
        
        uniswapV2RouterAddress = _uniswapV2RouterAddress;

        feeRecipientSetter = _feeRecipientSetter;
        feeRecipient = _feeRecipient;
    }


    /// @notice Returns the total number of tokens created by this factory
    /// @return The length of the allTokenAddresses array
    function allTokensLength() external view returns (uint256) {
        return allTokenAddresses.length;
    }

    function createToken(
        string memory name,
        string memory symbol,
        string memory tokenURI,
        uint256 reserveRatio,
        uint256 ethAmountForLiquidity,
        uint256 ethAmountForLiquidityFee,
        uint256 ethAmountForDevReward,
        uint256 tokenSupplyToSell
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
            reserveRatio
        );

        require(
            token.transfer(address(bondingCurve), token.totalSupply()),
            "ERC20 transfer failed"
        );

        getTokenBondingCurve[address(token)] = address(bondingCurve);
        getReserveRatio[address(bondingCurve)] = reserveRatio;
        allTokenAddresses.push(address(token));

        emit TokenCreated(
            address(token),
            address(bondingCurve),
            reserveRatio
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
}
