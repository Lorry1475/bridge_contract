const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");
const BigNumber = require('bignumber.js');
var Web3 = require('web3')
var assert = require("assert")
const util = require('ethereumjs-util');
const { FormatTypes } = require("ethers/lib/utils");

async function main() {
  const [owner, add1, add2, add3] = await ethers.getSigners();
  const Bridge = await ethers.getContractFactory("BridgeV1");
  var bridge = await Bridge.deploy();
  var bridge = await bridge.deployed();

  const ERC20 = await ethers.getContractFactory("ERC20");
  const erc20 = await ERC20.deploy("USDT", "USDT");
  await erc20.deployed();

  let value = BigInt("10000000000000000000000000")
  await erc20._mint(add1.address, value)

  console.log("erc20.address", erc20.address)
  console.log('bridge address', bridge.address)

  // {

  //   let wallet = "t2wvadrl6u4jxws7ahxqccb4ejq3elp6mxvrtzova"
  //   let tx = await bridge.connect(add1).depositEth(fil_networkid, wallet, { value: 10000000 })
  //   console.log(tx)
  // }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

