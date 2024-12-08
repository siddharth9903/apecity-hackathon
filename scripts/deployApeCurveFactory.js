const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // const setupParams = {
    //     tokenTotalSupply: '1000000000',
    //     swapFeePercentage: 1,
    //     virtualTokenReserve: ethers.parseEther('1000'),
    //     virtualEthReserve: 8571428,
    //     ethAmountForLiquidity: ethers.parseEther('4'),
    //     ethAmountForLiquidityFee: ethers.parseEther('0.100000'),
    //     ethAmountForDevReward: ethers.parseEther('0.10000'),
    //     uniswapRouterAddress: "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24", //for base
    //     feeRecipient: '0x7649aaa094a9d8b6FD15a63bF113069dE68a7460',
    //     feeRecipientSetter: '0xDF10c2Fa59BBEEDF419FE1C9B74a747D4b3DbCc7',
    //     standardReserveRatio: 500000
    // };
    const setupParams = {
        tokenTotalSupply: '1000000000',
        swapFeePercentage: '1',
        // uniswapRouterAddress: "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24", //for base
        // // uniswapRouterAddress: "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24", //for basefork
        // // uniswapRouterAddress: "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24", //for base
        // uniswapRouterAddress: "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24", //for bnb
        uniswapRouterAddress: "0x70085a09D30D6f8C4ecF6eE10120d1847383BB57", //for moonbeam
        feeRecipient: '0x7649aaa094a9d8b6FD15a63bF113069dE68a7460',
        feeRecipientSetter: '0xDF10c2Fa59BBEEDF419FE1C9B74a747D4b3DbCc7',
    };

    console.log("Deploying ApeCurveFactory...");
    const ApeCurveFactory = await ethers.getContractFactory("ApeCurveFactory");
    const apeCurveFactoryContract = await ApeCurveFactory.deploy(
        setupParams.tokenTotalSupply,
        setupParams.swapFeePercentage,
        setupParams.uniswapRouterAddress,
        setupParams.feeRecipient,
        setupParams.feeRecipientSetter,
    );

    await apeCurveFactoryContract.waitForDeployment();
    console.log("ApeCurveFactory deployed to:", apeCurveFactoryContract.target);

    // await tenderly.verify({
    //     address : ApeCurveFactoryContract.target,
    //     name: "ApeCurveFactory",
    // });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log("errorrrr", error);
        console.error(error);
        process.exit(1);
    });

//     `
// TENDERLY_PRIVATE_VERIFICATION=true \
// TENDERLY_AUTOMATIC_VERIFICATION=true \
// npx hardhat run scripts/deployApeCurveFactory.js --network tenderly
//     `

// "npx hardhat run scripts/deployApeCurveFactory.js --network basefork"
// 0x9c6f1be1be7603029bb067bc554136e907620a5d   23401447

// "npx hardhat run scripts/deployApeCurveFactory.js --network base"
// 0x9C6f1BE1Be7603029bB067BC554136e907620A5d   23410276

// "npx hardhat run scripts/deployApeCurveFactory.js --network moonbeam"
// 0x9C6f1BE1Be7603029bB067BC554136e907620A5d   8654562