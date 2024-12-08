const { ethers } = require("hardhat");

async function main() {
    const privateKey = ""
    const wallet = new ethers.Wallet(privateKey);

    console.log("New Wallet Address:", wallet.address);
    console.log("Private Key:", wallet.privateKey);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

// npx hardhat run scripts/wallet.js
