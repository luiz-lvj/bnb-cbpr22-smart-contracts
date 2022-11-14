
const hre = require("hardhat");

async function main() {
  const MedicalData = await hre.ethers.getContractFactory("MedicalData");
  const medicalData = await MedicalData.deploy();

  await medicalData.deployed();

  console.log(
    `MedicalData deployed to ${medicalData.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});