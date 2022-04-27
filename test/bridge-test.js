const { expect, assert } = require("chai");
const { ethers, web3 } = require("hardhat");
var Web3 = require('web3')
const bridgeContract = "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318"
const erc20Contract = "0x610178dA211FEF7D417bC0e6FeD39F05609AD788"
let fil_networkid = 1
let icp_networkid = 2
describe("bridge", function () {
    if (typeof web3 !== 'undefined') {
        web3 = new Web3(web3.currentProvider);
    } else {
        var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
    }
    let tokenCanister = "rrkah-fqaaa-aaaaa-aaaaq-cai"
    let tokenCanister2 = "ryjl3-tyaaa-aaaaa-aaaba-cai"
    let eth = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    it("test add  asset", async function () {
        const [owner, add1, add2, add3] = await ethers.getSigners();
        let bridge = await ethers.getContractAt("BridgeV1", bridgeContract);

        await bridge.addNetWork(fil_networkid)
        await bridge.addNetWork(icp_networkid)
        let res = await bridge.network(fil_networkid)
        assert.equal(res, true)
        res = await bridge.network(icp_networkid)
        assert.equal(res, true)
        res = await bridge.network(3)
        assert.equal(res, false)
        let fil_asset = {
            token: "t2wvadrl6u4jxws7ahxqccb4ejq3elp6mxvrtzova",
            symbol: "usdt",
            decimal: 18,
            exist: true
        }
        let icp_asset = {
            token: "wyra5-vplea-ppq4r-qyupt-h5sld-epi6m-3pg33-poem5-uehrw-3i6tc-pqe",
            symbol: "usdt",
            decimal: 18,
            exist: true
        }
        let EthAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        await bridge.addAsset(fil_networkid, erc20Contract, fil_asset)
        await bridge.addAsset(icp_networkid, erc20Contract, icp_asset)
        await bridge.addAsset(fil_networkid, EthAddress, fil_asset)
        await bridge.addAsset(icp_networkid, EthAddress, icp_asset)
        let get_fil_asset = await bridge.assetPipeline(erc20Contract, fil_networkid)
        assert.equal(get_fil_asset.token, fil_asset.token)

        let get_ic_asset = await bridge.assetPipeline(erc20Contract, icp_networkid)
        assert.equal(get_ic_asset.token, icp_asset.token)
        // let recipt = await web3.eth.getTransactionReceipt(res.hash)
        // assert(recipt.status == true, "bridge contract init failed")
    });



    it("test depositEth ", async function () {

        const [owner, add1, add2, add3] = await ethers.getSigners();
        let bridge = await ethers.getContractAt("BridgeV1", bridgeContract);
        let icWallet = "rrkab-fqaaa-aaaaa-aaaaq-cai"
        let balanceBefore = await web3.eth.getBalance(bridgeContract)
        let nonceBefore = await bridge.accountNonce(add1.address)
        let res = await bridge.connect(add1).depositEth(icp_networkid, icWallet, { value: 100000 })

        let recipt = await web3.eth.getTransactionReceipt(res.hash)
        assert(recipt.status == true, "depositEth failed")
        let balanceAfter = await web3.eth.getBalance(bridgeContract)
        assert(balanceAfter - balanceBefore == 100000, "depositEth Different quantity")
        let nonceAfter = await bridge.accountNonce(add1.address)
        assert(nonceAfter - nonceBefore == 1, "account nonce Different quantity")


        balanceBefore = await web3.eth.getBalance(bridgeContract)
        nonceBefore = await bridge.accountNonce(add1.address)
        let fil_wallet = "t2wvadrl6u4jxws7ahxqccb4ejq3elp6mxvrtzova"
        res = await bridge.connect(add1).depositEth(fil_networkid, fil_wallet, { value: 100000 })

        recipt = await web3.eth.getTransactionReceipt(res.hash)
        assert(recipt.status == true, "depositEth failed")
        balanceAfter = await web3.eth.getBalance(bridgeContract)
        assert(balanceAfter - balanceBefore == 100000, "depositEth Different quantity")
        nonceAfter = await bridge.accountNonce(add1.address)
        assert(nonceAfter - nonceBefore == 1, "account nonce Different quantity")
    })

    it("test depositErc20Token ", async function () {
        const [owner, add1, add2, add3] = await ethers.getSigners();
        let bridge = await ethers.getContractAt("BridgeV1", bridgeContract);
        let erc20 = await ethers.getContractAt("ERC20", erc20Contract);
        let icWallet = "rrkab-fqaaa-aaaaa-aaaaq-cai"
        let value = BigInt("1000000")

        let res = await erc20.connect(add1).approve(bridgeContract, value)
        let recipt = await web3.eth.getTransactionReceipt(res.hash)
        assert(recipt.status == true, "approve failed")
        let allowance = await erc20.allowance(add1.address, bridgeContract)
        assert(allowance >= value, "allowance not enough")

        let nonceBefore = await bridge.accountNonce(add1.address)
        let balanceBefore = await erc20.balanceOf(bridgeContract)

        res = await bridge.connect(add1).depositErc20Token(erc20Contract, icp_networkid, value, icWallet)

        recipt = await web3.eth.getTransactionReceipt(res.hash)

        assert(recipt.status == true, "depositErc20Token failed")
        let nonceAfter = await bridge.accountNonce(add1.address)
        let balanceAfter = await erc20.balanceOf(bridgeContract)
        assert(balanceAfter - balanceBefore == value, "depositErc20Token Different quantity")
        assert(nonceAfter - nonceBefore == 1, "account nonce Different quantity")



        let filWallet = "rrkab-fqaaa-aaaaa-aaaaq-cai"
        res = await erc20.connect(add1).approve(bridgeContract, value)
        recipt = await web3.eth.getTransactionReceipt(res.hash)
        assert(recipt.status == true, "approve failed")
        allowance = await erc20.allowance(add1.address, bridgeContract)
        assert(allowance >= value, "allowance not enough")

        nonceBefore = await bridge.accountNonce(add1.address)
        balanceBefore = await erc20.balanceOf(bridgeContract)

        res = await bridge.connect(add1).depositErc20Token(erc20Contract, fil_networkid, value, filWallet)

        recipt = await web3.eth.getTransactionReceipt(res.hash)

        assert(recipt.status == true, "depositErc20Token failed")
        nonceAfter = await bridge.accountNonce(add1.address)
        balanceAfter = await erc20.balanceOf(bridgeContract)
        assert(balanceAfter - balanceBefore == value, "depositErc20Token Different quantity")
        assert(nonceAfter - nonceBefore == 1, "account nonce Different quantity")

        let event_logs = web3.eth.abi.decodeLog([{
            type: 'address',
            name: 'from'
        }, {
            type: 'uint256',
            name: 'amount',
        }, {
            type: 'uint256',
            name: 'networkid',
        }, {
            type: 'uint256',
            name: 'nonce',
        }, {
            type: 'uint256',
            name: 'blockNumber',
        }, {
            type: 'address',
            name: 'fromAsset',
        }, {
            type: 'string',
            name: 'toAsset',
        }, {
            type: 'string',
            name: 'to',
        }], recipt.logs[recipt.logs.length - 1].data)
        console.log(event_logs)

    })


    // it("test getfee ", async function () {
    //     let bridge = await ethers.getContractAt("BridgeV1", bridgeContract);
    //     let value = 1;
    //     let fee = await bridge.getFee(value)
    //     assert(fee == 0, `get fee err,value is ${value}`)
    //     value = BigInt("10000000000000000000000000");
    //     fee = await bridge.getFee(value)
    //     assert(fee == BigInt("10000000000000000000000"), `get fee err,value is ${value}`)

    //     value = BigInt("3102220500089000540001293");
    //     fee = await bridge.getFee(value)
    //     assert(fee == BigInt("3102220500089000540001"), `get fee err,value is ${value}`)

    //     value = BigInt("1293");
    //     fee = await bridge.getFee(value)
    //     assert(fee == BigInt("1"), `get fee err,value is ${value}`)
    //     value = BigInt("999");
    //     fee = await bridge.getFee(value)
    //     assert(fee == BigInt("0"), `get fee err,value is ${value}`)

    //     value = BigInt("0");
    //     fee = await bridge.getFee(value)
    //     assert(fee == BigInt("0"), `get fee err,value is ${value}`)
    // })
    // it("test abi encode", async function () {
    //     let abiCoder = new ethers.utils.AbiCoder()
    //     let res = abiCoder.encode(['tupe(tuple(string,uint8))'], [[["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", 0]]])
    //     console.log("res", res)
    // })
});