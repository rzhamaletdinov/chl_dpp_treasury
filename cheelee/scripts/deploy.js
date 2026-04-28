const { ethers, upgrades } = require("hardhat");

const REQUIRED_ENV = ["CASES", "GLASSES", "SIGNER", "LEE", "CHEEL", "USDT"];

function readInitializeArgs() {
  const missing = REQUIRED_ENV.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(
      `Missing required env vars: ${missing.join(", ")}. ` +
        `Copy .env.example to .env and fill them in.`
    );
  }
  const { CASES, GLASSES, SIGNER, LEE, CHEEL, USDT } = process.env;
  return [CASES, GLASSES, SIGNER, LEE, CHEEL, USDT];
}

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  console.log(
    `Deploying Treasury from ${deployer.address} on chainId=${network.chainId}`
  );

  const args = readInitializeArgs();

  const Treasury = await ethers.getContractFactory("Treasury");
  const proxy = await upgrades.deployProxy(Treasury, args, {
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
    "\nNote: ownership of the Treasury (via proxy) is automatically " +
      "transferred to the hardcoded GNOSIS address inside `initialize`. " +
      "The ProxyAdmin's owner is the deployer; transfer it to the same " +
      "Gnosis Safe manually via ProxyAdmin.transferOwnership(...)."
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
