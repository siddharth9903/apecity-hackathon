

const { ethers } = require("hardhat");

async function main() {
    const bondingCurveContractAddress = "0x3be90ef55bdec4038ca4007759ed7d7dec9ff2c6"
    const tokenContractAddress = "0xcd693d3b056641f1a46b4ca35c079acf6b3ed53e"

    const [deployer] = await ethers.getSigners();
    let buyer = deployer

    const bondingCurve = await ethers.getContractAt("ApeBondingCurve", bondingCurveContractAddress);
    const token = await ethers.getContractAt("ERC20FixedSupply", tokenContractAddress);

    let buyerEthBalance = await ethers.provider.getBalance(buyer); 
    console.log('buyerEthBalance',buyerEthBalance)

    let amountToBuy = ethers.parseEther("1.01")
    console.log('amountToBuy',amountToBuy)
    let buyTx = await bondingCurve["buy()"]({ value: amountToBuy });
    await buyTx.wait();
    console.log('buyTx', buyTx)

    let buyerTokenBalance = await token.balanceOf(buyer)
    console.log('buyerTokenBalance after buy', buyerTokenBalance)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// "npx hardhat run scripts/buyToken.js --network basefork"