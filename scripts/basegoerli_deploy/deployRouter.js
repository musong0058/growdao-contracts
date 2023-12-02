const {
    sendTxn,
    deployContract,
    contractAt,
    writeTmpAddresses,
    getFrameSigner,
    network,
    providers,
} = require("../shared/helpers");
const { expandDecimals } = require("../shared/utilities");
const {ethers} = require("ethers");

async function getBaseGoerliValues() {
    const provider = providers.basegoerli;
    const vault = await contractAt(
        "Vault",
        ""
    );
    return { provider, vault }
}

async function getRolluxTestValues() {
    const provider = providers.rolluxtest;
    const vault = await contractAt(
        "Vault",
        "0x46Ac5af1Ed4589ceC46EfABEd283bE73Cc13d480"
    );
    return { provider, vault }
}

async function getValues() {
    if (network === "basegoerli") {
        return getBaseGoerliValues()
    }
    if (network === "rolluxtest") {
        return getRolluxTestValues()
    }
}

async function main() {

    const { provider, vault } = await getValues();
    const signer = await getFrameSigner();
    console.log("signer.address:", await signer.address);
    console.log("chainId:", await signer.getChainId());

    const router = await deployContract("Router", [vault.address]);

    // const router = await contractAt(
    //     "Router",
    //     "0xBB595fe7037445c27D6Cdd8e1fC692e416971329"
    // );
    await sendTxn(vault.addRouter(router.address), "vault.addRouter('${router.address}')")
    // await sendTxn(router.setVault(vault.address), "bondRouter.setVault")

    // const bondSetting = await vault.getBondSetting(0);
    // console.log("bondSetting[0]:", bondSetting);
    // console.log("msg.value:", ethers.utils.parseEther("0.001"));

    await sendTxn(router.buy(signer.address, 0, {value: ethers.utils.parseEther("0.001"),
        gasLimit: "3000000"}), "router.buy");

    // await sendTxn(vault.initialize(swapV2Router, swapV2LpToken, bondToken, adminFeeTo), "vault.initialize");


    // const minter = { address: "0xAcdC274B853e01e9666E03c662d30A83B8F73080" };
    //
    // const gmx = await contractAt(
    //   "ODX",
    //   "0x7A9a466DE08747bC8Ad79aBA6D8dCE9D64E5C767"
    // );
    //
    // console.log("isMinter:", await gmx.isMinter(minter.address));
    // console.log("decimals:", await gmx.decimals());
    //
    // const amount = expandDecimals("100000", 18);
    // await sendTxn(gmx.mint(minter.address, amount), "gmx.mint(sender, true)");
    // await sendTxn(gmx.mint("0x1Ce32739c33Eecb06dfaaCa0E42bd04E56CCbF0d", amount), "gmx.mint(sender, true)");


    // await sendTxn(
    //   gmx.setMinter(minter.address, true),
    //   "gmx.setMinter(minter, true)"
    // );

    // senders = [
    //   "0xAcdC274B853e01e9666E03c662d30A83B8F73080", // paul
    //   "0xc71aABBC653C7Bd01B68C35B8f78F82A21014471", // xiaowu
    //   "0x1Ce32739c33Eecb06dfaaCa0E42bd04E56CCbF0d", // jiagang
    //   "0xc7816AB57762479dCF33185bad7A1cFCb68a7997", // kering
    // ];
    // const amount = expandDecimals("10000", 18);
    // for (let sender of senders) {
    //   await sendTxn(gmx.mint(sender, amount), "gmx.mint(sender, true)");
    // }



    // EsGMX
    //   const esGmx = await contractAt(
    //     "EsGMX",
    //     "0xf7B8fFCFd556c2BBbb36535e97d24610a9fE79E1"
    //   );
    //   //   await deployContract("GMX", [])
    //   //   const minter = { address: "0xc71aABBC653C7Bd01B68C35B8f78F82A21014471" };

    //   await sendTxn(
    //     esGmx.setMinter(minter.address, true),
    //     "gmx.setMinter(minter, true)"
    //   );

    //   senders = [
    //     "0xc71aABBC653C7Bd01B68C35B8f78F82A21014471", // xiaowu
    //     "0x1Ce32739c33Eecb06dfaaCa0E42bd04E56CCbF0d", // jiagang
    //     "0xc7816AB57762479dCF33185bad7A1cFCb68a7997", // kering
    //   ];
    //   const amount = expandDecimals("10000", 18);
    //   for (let sender of senders) {
    //     await sendTxn(esGmx.mint(sender, amount), "gmx.mint(sender, true)");
    //   }

    //   const reader = await contractAt(
    //     "Reader",
    //     "0x7C4c161a923dF21b1dd1d62b8620Ea24d6E928c4"
    //   );
    //   const pr = await contractAt(
    //     "PositionRouter",
    //     "0xFb0342D3cf1Ba81fc336195c4Ed6626eAb8e402B",
    //     null,
    //     {
    //       libraries: {
    //         PositionUtils: "0x811B1AE2A6addF28e39cD189a56F2413a7c69f5E",
    //       },
    //     }
    //   );
    //   const key = await pr.getRequestKey(
    //     "0xc71aABBC653C7Bd01B68C35B8f78F82A21014471",
    //     1
    //   );
    //   const data = await pr.increasePositionRequests(
    //     "0x524f666cf739da9f19964f0ad12dd2a0ffa9bc3316055018167e691bedcb7ad5"
    //   );
    //   console.log("data:", data);
    //   const positions = await reader.getPositions(
    //     "0x7531626E87BdA9B8511bea536136e5349EDacE89",
    //     "0xc71aABBC653C7Bd01B68C35B8f78F82A21014471",
    //     ["0xd41D4FeF58b8c008F6e4d9614f2Fa9ed2Aec8aAb"],
    //     ["0xd41D4FeF58b8c008F6e4d9614f2Fa9ed2Aec8aAb"],
    //     [true]
    //   );
    //   //   console.log("positions:", positions);
    //   for (let position of positions) {
    //     console.log("position:", position);
    //   }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });