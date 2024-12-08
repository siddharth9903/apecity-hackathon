require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter")
require('hardhat-ethernal');
require('dotenv').config();
/** @type import('hardhat/config').HardhatUserConfig */

// const tdly = require("@tenderly/hardhat-tenderly");
// tdly.setup();

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.25",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.6.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    defaultNetwork: "hardhat",
    //   ethernal: {
    //     apiToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmaXJlYmFzZVVzZXJJZCI6IjN3SkdqcVZhM1BNd3NpdnNzVVNXaXJYT2lJODIiLCJhcGlLZXkiOiI4MEoyMUM3LVJRUk1HMUgtSzdOU1RHOS1YN0RLN0I0XHUwMDAxIiwiaWF0IjoxNzE0MTI3MTcyfQ.VqaG2XpmFk9dTnui0NKVUQ8FpeOVw1hIB73FS4Aa4Do"
    //   },
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
        // tenderly: {
        //     url: "https://virtual.base.rpc.tenderly.co/1fc2e09b-1a7e-4895-ace9-a7fa5c88bc46",
        //     accounts: [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2],
        //     chainId: 8454
        // },
        basefork: {
            url: "https://virtual.base.rpc.tenderly.co/910edb69-358e-4833-a39f-23b99d34b10b",
            accounts: [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2],
            chainId: 8454
        },
        base: {
            url: "https://base-rpc.publicnode.com",
            accounts: [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2],
            chainId: 8453
        },
        bnb: {
            url: "https://bscrpc.com",
            accounts: [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2],
            chainId: 56
        },
        moonbeam: {
            url: "https://moonbeam.drpc.org",
            accounts: [process.env.PRIVATE_KEY_1, process.env.PRIVATE_KEY_2],
            chainId: 1284
        },
        localhost: {
            url: "http://0.0.0.0:8545/",
            accounts: [
                "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
                "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
                "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
                "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
                "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
            ],
            //   chainId: 1337
        }
    },
    tenderly: {
        username: "Siddharth009",
        project: "apefun",
        // Contract visible only in Tenderly.
        // Omitting or setting to `false` makes it visible to the whole world.
        // Alternatively, admin-rpc verification visibility using
        // an environment variable `TENDERLY_PRIVATE_VERIFICATION`.
        privateVerification: true,
    },
    mocha: {
        timeout: 200000, // Increase the timeout value if needed
    },
    // gasReporter: {
    //     enabled: true,
    //     currency: "USD",
    //     currencyDisplayPrecision: 4,
    //     coinmarketcap: "45afcfb7-e746-4d41-b46c-05d19d5d73aa",
    //     L2: "base",
    //     L2Etherscan: "IH8XC9YYCR6ZP5WDAKANWFG3KGZSPRDGBB",
    //     token: "ETH",
    //     gasPriceApi: "https://api.basescan.org/api?module=proxy&action=eth_gasPrice",
    //     showTimeSpent: true,
    // },
};