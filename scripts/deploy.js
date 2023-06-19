async function main() {
  const CropInsurance = await ethers.getContractFactory("CropInsurance");
  const cropInsurance = await CropInsurance.deploy();
  await cropInsurance.deployed();
  console.log("CropInsurance deployed to:", cropInsurance.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
      console.error(error);
      process.exit(1);
  });
