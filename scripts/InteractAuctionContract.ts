import { ethers } from "hardhat";
import ether from "ethers";
import hre from "hardhat";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "Interacting with Auction contract using account:",
    deployer.address
  );

  const auctionAddress = "0x51395038D74bC0E08b3A9cfDd226Ae1d0164f26A"; 
  const auction = await ethers.getContractAt("IAuction", auctionAddress);



  // Interactions
  // Create an auction
  const endTime = Math.floor(Date.now() / 1000) + 60; 

  const createAuctionTx = await auction.createAuction(
    "ItemX",
    hre.ethers.parseEther("10"),
    endTime
  );
  await createAuctionTx.wait();
  console.log("Auction created with item ItemX and min bid 10 tokens.");

  // Ensure the bid is committed before auction ends

  if (Math.floor(Date.now() / 1000) >= endTime) {
    console.error("Auction ended, cannot commit bid.");
    return;
  }

  //     // Commit a bid
  const bidAmount = hre.ethers.parseEther("15");
  const salt = 12345; // numeric salt
  const bidHash = ethers.solidityPackedKeccak256(
    ["uint256", "uint256"],
    [bidAmount, salt]
  );
  const tokenAddress = ""; // Replace with ERC20 token contract address
  const token = await ethers.getContractAt("ERC20", tokenAddress);

  console.log("Approving tokens...");
  await token.approve(auctionAddress, bidAmount);
  console.log("Tokens approved.");

  const allowance = await token.allowance(deployer.address, auctionAddress);
  console.log("Allowance:", allowance.toString());

  console.log("Committing bid with hash:", bidHash);

  const commitTx = await auction.commitBid(bidHash, bidAmount);
  await commitTx.wait();

  console.log("Waiting for auction to end...");
  await delay(60000);
  

  // Reveal a bid
  console.log("Revealing bid...");
  const revealTx = await auction.revealBid(bidAmount, salt);
  await revealTx.wait();
  console.log("Bid revealed.");

  // Wait for the auction to end
  console.log("Waiting for the auction to end...");
  await delay(60000); // Wait for 1 minute

  // Finalize the auction
  console.log("Finalizing auction...");
  const finalizeTx = await auction.finalizeAuction({ gasLimit: 3000000 });
  await finalizeTx.wait();
  console.log("Auction finalized.");
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
