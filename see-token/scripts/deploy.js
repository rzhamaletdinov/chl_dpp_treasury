const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  console.log(
    `Deploying SEE from ${deployer.address} on chainId=${network.chainId}`
  );

  const SEE = await ethers.getContractFactory("SEE");
  // initialize() takes no arguments: name/symbol are hardcoded in the contract.
  const proxy = await upgrades.deployProxy(SEE, [], {
    kind: "transparent",
    initializer: "initialize",
  });
  await proxy.waitForDeployment();

  const proxyAddress = await proxy.getAddress();
  const implementationAddress =
    await upgrades.erc1967.getImplementationAddress(proxyAddress);
  const proxyAdminAddress =
    await upgrades.erc1967.getAdminAddress(proxyAddress);

  console.log("Deployment finished:");
  console.log(JSON.stringify(
    {
      proxy: proxyAddress,
      implementation: implementationAddress,
      proxyAdmin: proxyAdminAddress,
    },
    null,
    2
  ));
  console.log(
    "\nNote: ownership of SEE (via proxy) is automatically transferred to the " +
      "hardcoded SEE_MULTISIG address inside `initialize`. If SEE_MULTISIG is " +
      "still address(0) (the TODO(see) placeholder), this deploy WILL revert " +
      "with 'Ownable: new owner is the zero address'. After a successful " +
      "deploy, transfer the ProxyAdmin's ownership to the same SEE multisig " +
      "manually via ProxyAdmin.transferOwnership(...)."
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
