// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

using ABDKMath64x64 for int128;

contract ApeFormula {
    uint256 private constant MAX_WEIGHT = 1000000;

    // uint256 public immutable RESERVE_RATIO;
    uint256 public immutable reserveRatio;
    uint256 public immutable TARGETED_POOL_BALANCE;
    uint256 public immutable TARGETED_SUPPLY;
    int128 public immutable SLOPE_FIXED;

    constructor(uint256 _reserveRatio, uint256 _targetedPoolBalance, uint256 _targetedSupply) {
        reserveRatio = _reserveRatio;
        TARGETED_POOL_BALANCE = _targetedPoolBalance;
        TARGETED_SUPPLY = _targetedSupply;
        SLOPE_FIXED = calculateSlope(_targetedPoolBalance, _targetedSupply);
    }

    // m = b / (r * s ^(1/r))
    function calculateSlope(uint256 _poolBalanceFinal, uint256 _supplyFinal) public view returns (int128) {
        uint256 poolBalanceFinal = _poolBalanceFinal / 10 ** 12;
        uint256 supplyFinal = _supplyFinal / 10 ** 18;

        int128 poolBalanceFixed = ABDKMath64x64.fromUInt(poolBalanceFinal);
        int128 supplyFixed = ABDKMath64x64.fromUInt(supplyFinal);
        int128 reserveRatioFixed = ABDKMath64x64.divu(reserveRatio, MAX_WEIGHT);

        int128 supplyRaiseToInversedReserveRatio =
            ABDKMath64x64.exp(ABDKMath64x64.inv(reserveRatioFixed).mul(ABDKMath64x64.ln(supplyFixed)));

        int128 slopeFixed = poolBalanceFixed.div(reserveRatioFixed.mul(supplyRaiseToInversedReserveRatio));
        return slopeFixed;
    }

    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint256 _depositAmount)
        public
        view
        returns (uint256)
    {
        // require(_connectorBalance > 0, "ApeFormula: ConnectorBalance not > 0");
        require(reserveRatio > 0, "ApeFormula: Connector Weight not > 0");
        require(reserveRatio <= MAX_WEIGHT, "ApeFormula: Connector Weight not <= MAX_WEIGHT");

        if (_depositAmount == 0) return 0;

        // Convert all inputs to fixed point
        int128 supplyFixed = ABDKMath64x64.fromUInt(_supply / 10 ** 18);
        int128 depositFixed = ABDKMath64x64.fromUInt(_depositAmount / 10 ** 12);
        int128 connectorBalanceFixed = ABDKMath64x64.fromUInt(_connectorBalance / 10 ** 12);

        // Calculate reserve ratio (reserveRatio / MAX_WEIGHT)
        // Then divide by MAX_WEIGHT using divu
        int128 reserveRatioFixed = ABDKMath64x64.divu(reserveRatio, MAX_WEIGHT);

        if (_supply == 0) {
            int128 temp1 = reserveRatioFixed.mul(SLOPE_FIXED);
            int128 temp2 = depositFixed.div(temp1);
            int128 result = ABDKMath64x64.exp(reserveRatioFixed.mul(ABDKMath64x64.ln(temp2)));

            uint256 result2 = ABDKMath64x64.toUInt(result);
            return result2 * 10 ** 18;
        }

        // Special case when reserve ratio is 100%
        if (reserveRatio == MAX_WEIGHT) {
            int128 result = supplyFixed.mul(depositFixed).div(connectorBalanceFixed);
            return ABDKMath64x64.toUInt(result);
        }

        int128 baseNum = depositFixed.add(connectorBalanceFixed);
        int128 base = baseNum.div(connectorBalanceFixed);

        // Calculate power = base ^ reserveRatio
        int128 power = ABDKMath64x64.exp(reserveRatioFixed.mul(ABDKMath64x64.ln(base)));

        // Calculate result = supply * (base ^ reserveRatio) - supply
        int128 mult = supplyFixed.mul(power);
        int128 result = mult.sub(supplyFixed);
        uint256 result2 = ABDKMath64x64.toUInt(result);

        return result2 * 10 ** 18;
    }

    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint256 _sellAmount)
        public
        view
        returns (uint256)
    {
        // // validate input
        require(_supply > 0, "ApeFormula: Supply not > 0.");
        require(_connectorBalance > 0, "ApeFormula: ConnectorBalance not > 0");
        require(reserveRatio > 0, "ApeFormula: Connector Weight not > 0");
        require(reserveRatio <= MAX_WEIGHT, "ApeFormula: Connector Weight not <= MAX_WEIGHT");
        // require(_sellAmount <= _supply, "ApeFormula: Sell Amount not <= Supply");

        if (_sellAmount == 0) return 0;

        if (_sellAmount == _supply) return _connectorBalance;

        // Convert inputs to fixed point
        int128 supplyFixed = ABDKMath64x64.fromUInt(_supply / 10 ** 18);
        int128 sellAmountFixed = ABDKMath64x64.fromUInt(_sellAmount / 10 ** 18);
        int128 connectorBalanceFixed = ABDKMath64x64.fromUInt(_connectorBalance / 10 ** 12);

        // Special case when reserve ratio is 100%
        if (reserveRatio == MAX_WEIGHT) {
            int128 result = connectorBalanceFixed.mul(sellAmountFixed).div(supplyFixed);
            return ABDKMath64x64.toUInt(result);
        }

        // Calculate base = supply / (supply - sellAmount)
        int128 denominator = supplyFixed.sub(sellAmountFixed);
        int128 base = supplyFixed.div(denominator);

        // Calculate exponent = MAX_WEIGHT / reserveRatio
        uint256 exponent = (MAX_WEIGHT * ABDKMath64x64.toUInt(ABDKMath64x64.fromUInt(1))) / reserveRatio;

        // Calculate result = base ^ exponent
        int128 power = ABDKMath64x64.pow(base, exponent);

        // Calculate: connectorBalance * power
        int128 temp1 = connectorBalanceFixed.mul(power);

        // Calculate: (connectorBalance * power - connectorBalance) / power
        int128 temp2 = temp1.sub(connectorBalanceFixed);
        int128 result = temp2.div(power);
        uint256 finalResult = ABDKMath64x64.toUInt(result);

        return finalResult * 10 ** 12;
    }

    function estimateEthInForExactTokensOut(uint256 _supply, uint256 _connectorBalance, uint256 _tokenAmountOut)
        public
        view
        returns (uint256)
    {
        // require(_connectorBalance > 0, "ApeFormula: ConnectorBalance not > 0");
        require(reserveRatio > 0, "ApeFormula: Connector Weight not > 0");
        require(reserveRatio <= MAX_WEIGHT, "ApeFormula: Connector Weight not <= MAX_WEIGHT");

        // Calculate reserve ratio (reserveRatio / MAX_WEIGHT)
        // First convert to fixed point number using fromUInt for reserveRatio
        int128 reserveRatioFixed = ABDKMath64x64.divu(reserveRatio, MAX_WEIGHT);

        int128 tokenAmountOutFixed = ABDKMath64x64.fromUInt(_tokenAmountOut / 10 ** 18);
        int128 connectorBalanceFixed = ABDKMath64x64.fromUInt(_connectorBalance / 10 ** 12);
        int128 supplyFixed = ABDKMath64x64.fromUInt(_supply / 10 ** 18);
        // Convert inputs to fixed point

        if (_tokenAmountOut == 0) return 0;

        if (_supply == 0) {
            int128 temp1 = reserveRatioFixed.mul(SLOPE_FIXED);
            int128 temp2 =
                ABDKMath64x64.exp(ABDKMath64x64.inv(reserveRatioFixed).mul(ABDKMath64x64.ln(tokenAmountOutFixed)));

            int128 result = temp1.mul(temp2);
            uint256 result2 = ABDKMath64x64.toUInt(result);

            return result2 * 10 ** 12;
        }
        // Special case: 100% reserve ratio
        if (reserveRatio == MAX_WEIGHT) {
            int128 result = tokenAmountOutFixed.mul(connectorBalanceFixed).div(supplyFixed);
            return ABDKMath64x64.toUInt(result);
        }

        // Calculate base = (tokenAmountOut + supply) / supply
        int128 numerator = tokenAmountOutFixed.add(supplyFixed);
        int128 base = numerator.div(supplyFixed);

        // Calculate exponent = MAX_WEIGHT / reserveRatio
        uint256 exponent = (MAX_WEIGHT * ABDKMath64x64.toUInt(ABDKMath64x64.fromUInt(1))) / reserveRatio;

        // Calculate power = base ^ exponent
        int128 power = ABDKMath64x64.pow(base, exponent);

        int128 temp = connectorBalanceFixed.mul(power);
        int128 result = temp.sub(connectorBalanceFixed);
        uint256 result2 = ABDKMath64x64.toUInt(result);

        return result2 * 10 ** 12;
    }
}
