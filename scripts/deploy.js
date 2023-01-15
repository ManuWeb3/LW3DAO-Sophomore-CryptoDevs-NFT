const { ethers } = require("hardhat");
const { WHITELIST_CONTRACT_ADDRESS, METADATA_URL } = require("../constants/index")
const {network} = require("hardhat")
const {developmentChains} = require("../helper-hardhat-config.js")
const {verify} = require("../utils/verify")

async function main() {
    const whitelistAddress = WHITELIST_CONTRACT_ADDRESS
    const metadataURL = METADATA_URL

    console.log("Deploying CryptoDevs...")
    const cryptoDevsContractFactory = await ethers.getContractFactory("CryptoDevs")

    const deployedCryptoDevsContract = await cryptoDevsContractFactory.deploy(
      metadataURL,  
      whitelistAddress        
    )

    await deployedCryptoDevsContract.deployTransaction.wait(10)
    // instead of .deployed()

    console.log(`CryptoDevs Address: ${deployedCryptoDevsContract.address}`)
    console.log("-------------------")
    
    //  2. Verify on Etherscan, if it's Goerli
    const args = [metadataURL, whitelistAddress]

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
      console.log("Verifying on GoerliEtherscan...")
      await verify(deployedCryptoDevsContract.address, args)
      //  it takes address and args of the S/C as parameters
      console.log("-------------------------------")
    }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });