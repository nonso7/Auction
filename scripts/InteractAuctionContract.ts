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

  const auctionAddress = "0x8Db44D92391A5F7Ec35fD075cEBdE8569C9e6E39"; // Replace with deployed Auction contract address
  const auction = await ethers.getContractAt("IAuction", auctionAddress);

//   const auction = Auction.attach(auctionAddress);

  // Check if the address has already committed a bid
//   const commitment = await auction.commitments(deployer.address);
//   if (
//     commitment.hash !==
//     "0x0000000000000000000000000000000000000000000000000000000000000000"
//   ) {
//     console.log("Bid already committed for this address.");
//     return;
//   }

  // Interactions
  // Create an auction
  const endTime = Math.floor(Date.now() / 1000) + 60; // Auction ends in 1 minute

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
  const tokenAddress = "0x527dF04B96b1FFF91A1914C0987900d9d8c60996"; // Replace with ERC20 token contract address
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
