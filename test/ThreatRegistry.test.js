const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('ThreatRegistry', function () {
  let Registry, registry, Oracle, oracleContract;
  let admin, reporter, oracle, analyst, stranger;

  beforeEach(async function () {
    [admin, reporter, oracle, analyst, stranger] = await ethers.getSigners();

    Registry = await ethers.getContractFactory('ThreatRegistry');
    registry = await Registry.connect(admin).deploy();
    await registry.deployed();

    Oracle = await ethers.getContractFactory('ThreatOracle');
    oracleContract = await Oracle.connect(admin).deploy(registry.address);
    await oracleContract.deployed();

    // Grant roles
    const REPORTER_ROLE = await registry.REPORTER_ROLE();
    const ORACLE_ROLE = await registry.ORACLE_ROLE();
    const ANALYST_ROLE = await registry.ANALYST_ROLE();

    await registry.connect(admin).grantRole(REPORTER_ROLE, reporter.address);
    await registry.connect(admin).grantRole(ORACLE_ROLE, oracleContract.address);
    await registry.connect(admin).grantRole(ANALYST_ROLE, analyst.address);
  });

  it('allows reporter to report a threat and emits event', async function () {
    const tx = await registry.connect(reporter).reportThreat('scanner-1', 7, 'ipfs://QmMeta');
    const rc = await tx.wait();
    const ev = rc.events.find(e => e.event === 'ThreatReported');
    expect(ev).to.not.be.undefined;
    const id = ev.args[0];
    const data = await registry.getThreat(id);
    expect(data[0]).to.equal(id);
    expect(data[1]).to.equal(reporter.address);
  });

  it('blocks unauthorized reporters', async function () {
    await expect(registry.connect(stranger).reportThreat('x', 1, '')).to.be.reverted;
  });

  it('oracle can confirm threat and score increases', async function () {
    const tx = await registry.connect(reporter).reportThreat('scanner-1', 8, 'ipfs://meta');
    const rc = await tx.wait();
    const id = rc.events.find(e => e.event === 'ThreatReported').args[0];

    // Confirm via oracle adapter: only ORACLE_ROLE can call registry.confirmThreat, and oracleContract has the role
    await oracleContract.connect(admin).confirm(id); // oracleContract's admin calls confirm func (which itself calls registry.confirmThreat)

    const t = await registry.getThreat(id);
    expect(t[5]).to.equal(1); // confirmations

    const score = await registry.getThreatScore(id);
    expect(score).to.be.a('number');
    expect(Number(score)).to.be.greaterThan(0);
  });

  it('analyst can update and resolve threats', async function () {
    const tx = await registry.connect(reporter).reportThreat('scanner-2', 5, 'ipfs://meta2');
    const rc = await tx.wait();
    const id = rc.events.find(e => e.event === 'ThreatReported').args[0];

    await registry.connect(analyst).updateThreatMetadata(id, 6, 'ipfs://meta2-v2');
    let t = await registry.getThreat(id);
    expect(t[3]).to.equal(6);

    await registry.connect(analyst).resolveThreat(id);
    t = await registry.getThreat(id);
    expect(t[6]).to.equal(true); // resolved
  });

  it('prevents updating resolved threats', async function () {
    const tx = await registry.connect(reporter).reportThreat('scanner-3', 3, 'ipfs://m');
    const rc = await tx.wait();
    const id = rc.events.find(e => e.event === 'ThreatReported').args[0];

    await registry.connect(analyst).resolveThreat(id);
    await expect(registry.connect(reporter).updateThreatMetadata(id, 4, 'ipfs://m2')).to.be.revertedWith('threat resolved');
  });
});
