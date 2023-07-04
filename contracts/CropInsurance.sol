const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
    time,
    loadFixture
} = require("@nomicfoundation/hardhat-network-helpers");


describe("Insurance", function(){
    async function setup() {
        const [ deployer, otherAccount ] = await ethers.getSigners();

        // Load contract
        const Insurance = await ethers.getContractFactory("Insurance");
        const Token = await ethers.getContractFactory("TestToken");

        // Deploy contract
        const cUSD = await Token.deploy();
        const insurance = await Insurance.deploy(await cUSD.getAddress());

        // OtherAccount request faucet
        await cUSD.connect(otherAccount).faucet();

        return { deployer, otherAccount, cUSD, insurance };
    }

    it("Register", async function(){
        const { otherAccount, cUSD, insurance } = await loadFixture(setup);
        const amount = ethers.parseEther("60");

        // Register insurance
        await cUSD.connect(otherAccount).approve(await insurance.getAddress(), amount);
        await insurance.connect(otherAccount).register(amount);

        // Check data
        const insuranceData = await insurance.connect(otherAccount).getInsurance();
        expect(insuranceData[0]).to.be.equal(amount);
        expect(insuranceData[1]).to.be.equal(ethers.parseEther("1200"));
        expect(insuranceData[2]).to.be.equal(amount);
        expect(await insurance.balanceOf(otherAccount.address)).to.be.equal(ethers.parseEther("1200"));
        expect(await cUSD.balanceOf(await insurance.getAddress())).to.be.equal(ethers.parseEther("60"));
    });

    it("Claim", async function(){
        const { otherAccount, cUSD, insurance } = await loadFixture(setup);
        const amount = ethers.parseEther("60");

        // Register insurance
        await cUSD.connect(otherAccount).approve(await insurance.getAddress(), amount);
        await insurance.connect(otherAccount).register(amount);

        // Get insurance data
        const citAmount = await insurance.balanceOf(otherAccount.address);
        const insuranceData = await insurance.connect(otherAccount).getInsurance();

        // Increase time
        time.increaseTo(insuranceData[5]);

        // Claim
        await insurance.connect(otherAccount).claim(citAmount);
        const newInsuranceData = await insurance.connect(otherAccount).getInsurance();
        expect(newInsuranceData[0]).to.be.equal(ethers.parseEther("0"));
        expect(newInsuranceData[1]).to.be.equal(ethers.parseEther("0"));
        expect(await insurance.balanceOf(otherAccount.address)).to.be.equal(ethers.parseEther("0"));
        expect(await cUSD.balanceOf(await otherAccount.address)).to.be.equal(ethers.parseEther("200"));
    });

    it("Pay Insurance", async function(){
        const { otherAccount, cUSD, insurance } = await loadFixture(setup);
        const amount = ethers.parseEther("60");

        // Register insurance
        await cUSD.connect(otherAccount).approve(await insurance.getAddress(), amount);
        await insurance.connect(otherAccount).register(amount);

        // Get insurance data
        const citAmount = await insurance.balanceOf(otherAccount.address);
        const insuranceData = await insurance.connect(otherAccount).getInsurance();

        // Increase time
        time.increaseTo(insuranceData[5]);

        // Pay insurance
        await cUSD.connect(otherAccount).approve(await insurance.getAddress(), amount);
        await insurance.connect(otherAccount).pay(amount);
        const newInsuranceData = await insurance.connect(otherAccount).getInsurance();

        expect(newInsuranceData[0]).to.be.equal(ethers.parseEther("120"));
        expect(newInsuranceData[1]).to.be.equal(ethers.parseEther("2400"));
        expect(await cUSD.balanceOf(await insurance.getAddress())).to.be.equal(ethers.parseEther("120"));
        expect(await insurance.balanceOf(otherAccount.address)).to.be.equal(ethers.parseEther("2400"));
    })
})