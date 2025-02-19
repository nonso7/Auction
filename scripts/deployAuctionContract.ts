import { ethers } from "hardhat";
import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";

async function main() {
    const Auction = await ethers.getContractFactory("Auction");
    const TokenAddress1 = "0xF38caa9EfaA1A7a4b580F4869e97e007a736d335";
    const TokenAddress2 = "0xcdD584D7932f92deC418459a24e98fa24fdcd673";

    const ONE_Hour_SECS = 1 * 60 * 60;
    

    const duration = (await time.latest()) + ONE_Hour_SECS;

    const startPrice = await ethers.parseEther("2");
    const endPrice = await ethers.parseEther("1");
    const startTime = await time.latest();

    // Deploy Auction contract
    const auction = await Auction.deploy(TokenAddress1, TokenAddress2, startPrice, endPrice, startTime, duration);

    //await auction.deployed();
    console.log("Auction deployed to:", await auction.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});


