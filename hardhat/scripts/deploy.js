const { ethers } = require("hardhat");
const {
  LINK_TOKEN,
  VRF_COORDINATOR,
  KEY_HASH,
  FEE,
} = require("../constants/index.js");

async function main() {
  const RandomWinnerGame = await ethers.getContractFactory("RandomWinnerGame");
  const randomWinnerGame = await RandomWinnerGame.deploy(
    VRF_COORDINATOR,
    LINK_TOKEN,
    KEY_HASH,
    FEE
  );
  await randomWinnerGame.deployed();
  console.log("RandomWinnerGame deployed to:", randomWinnerGame.address);

  console.log(
    "Sleeping for 30 seconds to wait for the contract to be verified..."
  );
  await new Promise((resolve) => setTimeout(resolve, 30000));

  await hre.run("verify:verify", {
    address: randomWinnerGame.address,
    constructorArguments: [VRF_COORDINATOR, LINK_TOKEN, KEY_HASH, FEE],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
