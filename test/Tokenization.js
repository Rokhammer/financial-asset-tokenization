const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Tokenization", function () {
    tokenIncome = [15, 10, 20];


    beforeEach(async function () {
        [owner, regulator, ...user] = await ethers.getSigners();
        packageOwner = [user[0].address, user[1].address, user[0].address, user[2].address];

        Tokenization = await ethers.getContractFactory("Tokenization");
        hash = "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563"
        tokenization = await Tokenization.deploy(hash, 10000, packageOwner, tokenIncome);
    });


    it("Should return balance of the owners", async function () {
        expect(await tokenization.balanceOf(user[0].address)).to.equal(2);
        expect(await tokenization.balanceOf(user[1].address)).to.equal(1);
        expect(await tokenization.balanceOf(user[2].address)).to.equal(1);
        expect(await tokenization.balanceOf(user[3].address)).to.equal(0);
    });


    it("Should return owners of packages", async function () {
        expect(await tokenization.ownerOf(0)).to.equal(user[0].address);
        expect(await tokenization.ownerOf(1)).to.equal(user[1].address);
        expect(await tokenization.ownerOf(2)).to.equal(user[0].address);
        expect(await tokenization.ownerOf(3)).to.equal(user[2].address);
        await expect(tokenization.ownerOf(4)).to.be.reverted;
    });


    it("Should transfer tokens from owner", async function () {
        await expect(tokenization.connect(user[1]).transferFrom(user[0].address, user[1].address, 0)).to.be.reverted;
        await expect(tokenization.connect(user[2]).transferFrom(user[0].address, user[1].address, 0)).to.be.reverted;
        await expect(tokenization.connect(user[3]).transferFrom(user[0].address, user[1].address, 0)).to.be.reverted;
        await tokenization.connect(user[0]).transferFrom(user[0].address, user[1].address, 0);
        expect(await tokenization.ownerOf(0)).to.equal(user[1].address);
    });


    it("Should transfer tokens from operator", async function () {
        await tokenization.connect(user[0]).setApprovalForAll(user[1].address, true);
        await tokenization.connect(user[1]).transferFrom(user[0].address, user[1].address, 0);
        await tokenization.connect(user[1]).transferFrom(user[0].address, user[3].address, 2);
        expect(await tokenization.ownerOf(0)).to.equal(user[1].address);
        expect(await tokenization.ownerOf(1)).to.equal(user[1].address);
        expect(await tokenization.ownerOf(2)).to.equal(user[3].address);
        expect(await tokenization.ownerOf(3)).to.equal(user[2].address);
    });


    it("Should transfer approved tokens", async function () {
        await tokenization.connect(user[0]).approve(user[1].address, 0);
        await tokenization.connect(user[1]).transferFrom(user[0].address, user[1].address, 0);
        expect(await tokenization.ownerOf(0)).to.equal(user[1].address);
        expect(await tokenization.ownerOf(1)).to.equal(user[1].address);
        expect(await tokenization.ownerOf(2)).to.equal(user[0].address);
        expect(await tokenization.ownerOf(3)).to.equal(user[2].address);
    });


    it("Should show approved tokens", async function () {
        expect(await tokenization.getApproved(0)).to.equal(ethers.constants.AddressZero);
        await tokenization.connect(user[0]).approve(user[1].address, 0);
        expect(await tokenization.getApproved(0)).to.equal(user[1].address);
        await tokenization.connect(user[1]).transferFrom(user[0].address, user[1].address, 0);
        expect(await tokenization.getApproved(0)).to.equal(ethers.constants.AddressZero);
    });


    it("Should show operator", async function () {
        expect(await tokenization.isApprovedForAll(user[0].address, user[1].address)).to.equal(false);
        await tokenization.connect(user[0]).setApprovalForAll(user[1].address, true);
        expect(await tokenization.isApprovedForAll(user[0].address, user[1].address)).to.equal(true);
        await tokenization.connect(user[0]).setApprovalForAll(user[1].address, false);
        expect(await tokenization.isApprovedForAll(user[0].address, user[1].address)).to.equal(false);
    });


    it("Should pay reward", async function () {
        await tokenization.connect(owner).payReward([1, 1, 1], [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]], 0, {value: 180});
    });
});
