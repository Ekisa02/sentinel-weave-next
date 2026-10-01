const hre = require('hardhat');

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log('Deploying contracts with', deployer.address);

  const Registry = await hre.ethers.getContractFactory('ThreatRegistry');
  const registry = await Registry.deploy();
  await registry.deployed();
  console.log('ThreatRegistry deployed to:', registry.address);

  const Oracle = await hre.ethers.getContractFactory('ThreatOracle');
  const oracle = await Oracle.deploy(registry.address);
  await oracle.deployed();
  console.log('ThreatOracle deployed to:', oracle.address);

  // Grant roles (example): grant REPORTER_ROLE to deployer for testing/demo
  const REPORTER_ROLE = await registry.REPORTER_ROLE();
  const ORACLE_ROLE = await registry.ORACLE_ROLE();
  const ANALYST_ROLE = await registry.ANALYST_ROLE();

  await registry.grantRole(REPORTER_ROLE, deployer.address);
  await registry.grantRole(ORACLE_ROLE, oracle.address);
  await registry.grantRole(ANALYST_ROLE, deployer.address);

  console.log('Granted REPORTER_ROLE to deployer and ORACLE_ROLE to oracle contract');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
