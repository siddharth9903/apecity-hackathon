const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther, formatEther } = ethers;

describe.only("ApeFormula", function () {
    let apeFormula;
    let owner;

    const RESERVE_RATIO = 500000; // 50% in PPM (parts per million)
    const TARGETED_POOL_BALANCE = parseEther("4.2"); // 4.2 ETH
    const TARGETED_SUPPLY = parseEther("700000000"); // 700000000 tokens

    beforeEach(async function () {
        [owner] = await ethers.getSigners();

        const ApeFormula = await ethers.getContractFactory("ApeFormula");
        apeFormula = await ApeFormula.deploy(
            RESERVE_RATIO,
            TARGETED_POOL_BALANCE,
            TARGETED_SUPPLY
        );
        // apeFormula = await ApeFormula.deploy();
        await apeFormula.waitForDeployment();

        // Log the deployed values
        console.log("Contract deployed with:");
        console.log("RESERVE_RATIO:", RESERVE_RATIO.toString());
        console.log("TARGETED_POOL_BALANCE:", TARGETED_POOL_BALANCE.toString());
        console.log("TARGETED_SUPPLY:", TARGETED_SUPPLY.toString());
    });

    describe("calculateSlope", function () {
        it("should calculate slope correctly with initial values", async function () {
            try {
                // Test with the targeted values
                const slope = await apeFormula.calculateSlope(
                    TARGETED_POOL_BALANCE,
                    TARGETED_SUPPLY
                );

                console.log("Raw slope value:", slope.toString());

                // Convert the fixed-point number to a more readable format
                const formattedSlope = formatFixed(slope);
                console.log("Formatted slope:", formattedSlope.toString());

                // Add basic validation
                expect(slope).to.not.equal(0);
            } catch (error) {
                console.error("Error details:", error);
                throw error;
            }
        });
    });

    describe("calculatePurchaseReturn", function () {
        it("should calculate purchase correctly with initial values", async function () {
            try {

                // function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint256 _depositAmount, uint256 slope)

                // Test with the targeted values
                const purchaseReturn = await apeFormula.calculatePurchaseReturn(
                    parseEther("0"),
                    parseEther("0"),
                    parseEther("1")
                );


                // function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint256 _depositAmount)


                console.log("purchaseReturn raw value :", purchaseReturn.toString());
                console.log("purchaseReturn in eth :", formatEther(purchaseReturn.toString()), "eth");

                const purchaseReturn2 = await apeFormula.calculatePurchaseReturn(
                    purchaseReturn,
                    parseEther("1"),
                    parseEther("1")
                );

                console.log("purchaseReturn2 raw value :", purchaseReturn2.toString());
                console.log("purchaseReturn2 in eth :", formatEther(purchaseReturn2.toString()), "eth");


                console.log("purchaseReturn1 + purchaseReturn2 in eth :", formatEther(purchaseReturn.toString()) + formatEther(purchaseReturn2.toString()), "eth");


                const purchaseReturn3 = await apeFormula.calculatePurchaseReturn(
                    parseEther("0"),
                    parseEther("0"),
                    parseEther("2")
                );

                console.log("purchaseReturn3 raw value :", purchaseReturn3.toString());
                console.log("purchaseReturn3 in eth :", formatEther(purchaseReturn3.toString()), "eth");


                const ethIn = await apeFormula.estimateEthInForExactTokensOut(
                    parseEther("0"),
                    parseEther("0"),
                    purchaseReturn
                );

                console.log("ethIn raw value :", ethIn.toString());
                console.log("ethIn in eth :", formatEther(ethIn.toString()), "eth");


                const ethIn2 = await apeFormula.estimateEthInForExactTokensOut(
                    purchaseReturn,
                    parseEther("1"),
                    purchaseReturn2
                );

                console.log("ethIn2 raw value :", ethIn2.toString());
                console.log("ethIn2 in eth :", formatEther(ethIn2.toString()), "eth"); //1 ether



                const saleReturn = await apeFormula.calculateSaleReturn(
                    purchaseReturn,
                    parseEther("1"),
                    purchaseReturn
                );

                console.log("saleReturn raw value :", saleReturn.toString());
                console.log("saleReturn in eth :", formatEther(ethIn2.toString()), "eth"); //1 ether


                const saleReturn2 = await apeFormula.calculateSaleReturn(
                    purchaseReturn3,
                    parseEther("2"),
                    purchaseReturn2
                    // formatEther(purchaseReturn2.toString()) - formatEther(purchaseReturn.toString())
                );

                console.log("saleReturn2 raw value :", saleReturn2.toString());
                console.log("saleReturn2 in eth :", formatEther(saleReturn2.toString()), "eth"); //1 ether




                // Add basic validation
                // expect(slope).to.not.equal(0);
            } catch (error) {
                console.error("Error details:", error);
                throw error;
            }
        });
    });

    // describe("calculateEthInForExactTokenOut", function () {
    //     it("should estimate eth in correctly with initial values", async function () {
    //         try {

    //             // function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint256 _depositAmount, uint256 slope)

    //             // Test with the targeted values
    //             const ethIn = await apeFormula.calculatePurchaseReturn(
    //                 parseEther("0"),
    //                 parseEther("0"),
    //                 parseEther("1")
    //             );


    //             // function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint256 _depositAmount)


    //             console.log("purchaseReturn raw value :", purchaseReturn.toString());
    //             console.log("purchaseReturn in eth :", formatEther(purchaseReturn.toString()), "eth");

    //             const purchaseReturn2 = await apeFormula.calculatePurchaseReturn(
    //                 purchaseReturn,
    //                 parseEther("1"),
    //                 parseEther("1")
    //             );

    //             console.log("purchaseReturn2 raw value :", purchaseReturn2.toString());
    //             console.log("purchaseReturn2 in eth :", formatEther(purchaseReturn2.toString()), "eth");


    //             console.log("purchaseReturn1 + purchaseReturn2 in eth :", formatEther(purchaseReturn.toString()) + formatEther(purchaseReturn2.toString()), "eth");


    //             const purchaseReturn3 = await apeFormula.calculatePurchaseReturn(
    //                 parseEther("0"),
    //                 parseEther("0"),
    //                 parseEther("2")
    //             );

    //             console.log("purchaseReturn3 raw value :", purchaseReturn3.toString());
    //             console.log("purchaseReturn3 in eth :", formatEther(purchaseReturn3.toString()), "eth");



    //             // Add basic validation
    //             // expect(slope).to.not.equal(0);
    //         } catch (error) {
    //             console.error("Error details:", error);
    //             throw error;
    //         }
    //     });
    // });

    // Improved helper function to format the output of ABDKMath64x64 fixed-point numbers
    function formatFixed(value) {
        try {
            // Handle potential negative numbers
            const isNegative = value < 0;
            const absoluteValue = isNegative ? value * -1n : value;

            // Convert to decimal by dividing by 2^64
            const converted = ethers.getBigInt(absoluteValue.toString()) * ethers.getBigInt(1000000000000000000n) / ethers.getBigInt(2n ** 64n);

            return isNegative ? -converted : converted;
        } catch (error) {
            console.error("Error in formatFixed:", error);
            return "Error formatting value";
        }
    }
});