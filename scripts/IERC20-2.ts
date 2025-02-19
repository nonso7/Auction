import { ethers } from "hardhat";

async function main() {
    const token = await ethers.getContractFactory("EvictToken");

    // Deploy Auction contract
    const auction = await token.deploy();

    //await auction.deployed();
    console.log("Auction deployed to:", await auction.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

//0xcdD584D7932f92deC418459a24e98fa24fdcd673


