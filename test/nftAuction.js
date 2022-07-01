const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

let Token;
let hardhatToken;
let Q2Staking;
let deployedQ2Staking;
const secondsInSixMonths = 15811200;
const secondsInOneYears = 31536000;
const secondsInTwoYears = 63072000;
const currentTimeStampInSecond = (Date.now() / 1000) | 0;

let totalTokenToBeDistributed = (200000000 * 10 ** 18).toLocaleString(
  "fullwide",
  {
    useGrouping: false,
  }
);

describe("Q2Staking", function () {
  beforeEach(async () => {
    const [owner, addr1] = await ethers.getSigners();
    Token = await ethers.getContractFactory("TestToken");
    hardhatToken = await Token.deploy();
    Q2Staking = await ethers.getContractFactory("Q2Staking");
    deployedQ2Staking = await Q2Staking.deploy(
      hardhatToken.address,
      owner.address
    );
    await hardhatToken.approve(
      deployedQ2Staking.address,
      totalTokenToBeDistributed
    );
  });

  describe("Six Month Staking", function () {
    const rewardPercentage = 0.04;
    const stakeAmount = (100 * 10 ** 18).toLocaleString("fullwide", {
      useGrouping: false,
    });
    beforeEach(async () => {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.transfer(addr1.address, stakeAmount);
    });

    it("Revert Transaction with `ERC20: transfer amount exceeds balance` if Balance is Not Sufficient", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.connect(addr1).transfer(owner.address, stakeAmount);
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await expect(
        deployedQ2Staking.connect(addr1).stake(stakeAmount, 0)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("Revert Transaction with `ERC20: insufficient allowance` if Allowance is Not Sufficient", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await expect(
        deployedQ2Staking.connect(addr1).stake(stakeAmount, 0)
      ).to.be.revertedWith("ERC20: insufficient allowance");
    });

    it("Should Allow Account to Stake Q2", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 0);
      const vestingDetails = await deployedQ2Staking.stakingDetails(
        addr1.address,
        0
      );
      expect(
        Number(vestingDetails[0]).toLocaleString("fullwide", {
          useGrouping: false,
        })
      ).to.equal(
        (
          Number(stakeAmount) + Number(stakeAmount * rewardPercentage)
        ).toLocaleString("fullwide", {
          useGrouping: false,
        })
      );
    });

    it("Revert Transaction with `You do not have permission to unlock` If User Tries to Claim Q2 Without Staking", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);

      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("You do not have permission to unlock");
    });

    it("Should Allow Account to Claim Q2 After CoolDown Time Ends", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 0);
      await network.provider.send("evm_increaseTime", [
        secondsInSixMonths + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);
    });

    it("Revert Transaction with `You do not have permission to unlock` If User Tries to Claim Q2 Multiple Time", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 0);
      await network.provider.send("evm_increaseTime", [
        secondsInSixMonths + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);
      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("You do not have permission to unlock");
    });
  });
  describe("One Year Staking", function () {
    const rewardPercentage = 0.12;
    const stakeAmount = (100 * 10 ** 18).toLocaleString("fullwide", {
      useGrouping: false,
    });
    beforeEach(async () => {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.transfer(addr1.address, stakeAmount);
    });

    it("Revert Transaction with `ERC20: transfer amount exceeds balance` if Balance is Not Sufficient", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.connect(addr1).transfer(owner.address, stakeAmount);
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await expect(
        deployedQ2Staking.connect(addr1).stake(stakeAmount, 1)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("Revert Transaction with `ERC20: insufficient allowance` if Allowance is Not Sufficient", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await expect(
        deployedQ2Staking.connect(addr1).stake(stakeAmount, 1)
      ).to.be.revertedWith("ERC20: insufficient allowance");
    });

    it("Should Allow Account to Stake Q2", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 1);
      const vestingDetails = await deployedQ2Staking.stakingDetails(
        addr1.address,
        0
      );
      expect(
        Number(vestingDetails[0]).toLocaleString("fullwide", {
          useGrouping: false,
        })
      ).to.equal(
        (
          Number(stakeAmount) + Number(stakeAmount * rewardPercentage)
        ).toLocaleString("fullwide", {
          useGrouping: false,
        })
      );
    });

    it("Revert Transaction with `You do not have permission to unlock` If User Tries to Claim Q2 Without Staking", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);

      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("You do not have permission to unlock");
    });

    it("Should Allow Account to Claim Q2 After CoolDown Time Ends", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 1);
      await network.provider.send("evm_increaseTime", [
        secondsInOneYears + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);
    });

    it("Revert Transaction with `You do not have permission to unlock` If User Tries to Claim Q2 Multiple Time", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 1);
      await network.provider.send("evm_increaseTime", [
        secondsInOneYears + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);
      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("You do not have permission to unlock");
    });
  });
  describe("Two Year Staking", function () {
    const rewardPercentage = 0.322;
    const stakeAmount = (100 * 10 ** 18).toLocaleString("fullwide", {
      useGrouping: false,
    });
    beforeEach(async () => {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.transfer(addr1.address, stakeAmount);
    });

    it("Revert Transaction with `ERC20: transfer amount exceeds balance` if Balance is Not Sufficient", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.connect(addr1).transfer(owner.address, stakeAmount);
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await expect(
        deployedQ2Staking.connect(addr1).stake(stakeAmount, 2)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("Revert Transaction with `ERC20: insufficient allowance` if Allowance is Not Sufficient", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await expect(
        deployedQ2Staking.connect(addr1).stake(stakeAmount, 2)
      ).to.be.revertedWith("ERC20: insufficient allowance");
    });

    it("Should Allow Account to Stake Q2", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 2);
      const vestingDetails = await deployedQ2Staking.stakingDetails(
        addr1.address,
        0
      );
      expect(
        Number(vestingDetails[0]).toLocaleString("fullwide", {
          useGrouping: false,
        })
      ).to.equal(
        (
          Number(stakeAmount) + Number(stakeAmount * rewardPercentage)
        ).toLocaleString("fullwide", {
          useGrouping: false,
        })
      );
    });

    it("Revert Transaction with `You do not have permission to unlock` If User Tries to Claim Q2 Without Staking", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);

      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("You do not have permission to unlock");
    });

    it("Should Allow Account to Claim Q2 After CoolDown Time Ends", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 2);
      await network.provider.send("evm_increaseTime", [
        secondsInTwoYears + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);
    });

    it("Revert Transaction with `You do not have permission to unlock` If User Tries to Claim Q2 Multiple Time", async function () {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 2);
      await network.provider.send("evm_increaseTime", [
        secondsInTwoYears + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);
      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("You do not have permission to unlock");
    });
  });

  describe("MultiStaking", function () {
    const approveAmount = (100000000 * 10 ** 18).toLocaleString("fullwide", {
      useGrouping: false,
    });
    beforeEach(async () => {
      const [owner, addr1] = await ethers.getSigners();
      await hardhatToken.transfer(addr1.address, approveAmount);
      await hardhatToken
        .connect(addr1)
        .approve(deployedQ2Staking.address, totalTokenToBeDistributed);
    });

    it("Should Allow Account to Claim Q2 After CoolDown Time Ends", async function () {
      const stakeAmount = (100 * 10 ** 18).toLocaleString("fullwide", {
        useGrouping: false,
      });
      const [owner, addr1] = await ethers.getSigners();
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 0);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 1);
      await deployedQ2Staking.connect(addr1).stake(stakeAmount, 2);

      const stakingBalance = await deployedQ2Staking.stakingBalance(
        addr1.address
      );
      expect(Number(stakingBalance)).to.equal(3);

      const balance = await hardhatToken.balanceOf(addr1.address);

      const vestingDetails0 = await deployedQ2Staking.stakingDetails(
        addr1.address,
        0
      );
      const vestingDetails1 = await deployedQ2Staking.stakingDetails(
        addr1.address,
        1
      );
      const vestingDetails2 = await deployedQ2Staking.stakingDetails(
        addr1.address,
        2
      );
      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(0)
      ).to.be.revertedWith("It's not time to unlock");
      await network.provider.send("evm_increaseTime", [
        secondsInSixMonths + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(0);

      const balanceAfterFirstClaim = await hardhatToken.balanceOf(
        addr1.address
      );
      expect(Number(vestingDetails0[0]) + Number(balance)).to.equal(
        Number(balanceAfterFirstClaim)
      );

      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(1)
      ).to.be.revertedWith("It's not time to unlock");

      await network.provider.send("evm_increaseTime", [
        secondsInSixMonths + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(1);

      const balanceAfterSecondClaim = await hardhatToken.balanceOf(
        addr1.address
      );
      expect(
        Number(vestingDetails1[0]) + Number(balanceAfterFirstClaim)
      ).to.equal(Number(balanceAfterSecondClaim));

      await expect(
        deployedQ2Staking.connect(addr1).unlockQ2(2)
      ).to.be.revertedWith("It's not time to unlock");

      await network.provider.send("evm_increaseTime", [
        secondsInOneYears + 100,
      ]);
      await network.provider.send("evm_mine");
      await deployedQ2Staking.connect(addr1).unlockQ2(2);
    });
  });
});