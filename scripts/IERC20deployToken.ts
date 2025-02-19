import { ethers } from "hardhat";

async function main() {
    const token = await ethers.getContractFactory("Web3CXI");

    // Deploy Auction contract
    const auction = await token.deploy();

    //await auction.deployed();
    console.log("Auction deployed to:", await auction.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

//0xF38caa9EfaA1A7a4b580F4869e97e007a736d335
