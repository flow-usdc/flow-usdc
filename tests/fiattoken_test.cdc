import Test
import BlockchainHelpers
import "test_helpers.cdc"
import "FungibleToken"
import "FungibleTokenMetadataViews"
import "FiatToken"

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let recipient = Test.createAccount()

access(all) let VaultStoragePath = StoragePath(identifier: "USDCVault")!
access(all) let VaultBalancePubPath = PublicPath(identifier: "USDCVaultBalance")!
access(all) let VaultReceiverPubPath = PublicPath(identifier: "USDCVaultReceiver")!
access(all) let BlocklisterStoragePath = StoragePath(identifier: "USDCBlocklister")!
access(all) let PauserStoragePath = StoragePath(identifier: "USDCPauser")!
access(all) let MinterStoragePath = StoragePath(identifier: "USDCMinter")!
access(all) let tokenName = "USDC"
access(all) let version = "2.0.0"
access(all) let initTotalSupply = 1000.0
access(all) let initPaused = false

access(all)
fun setup() {
    deployWithArgs(
        "FlowEVMBridgeHandlerInterfaces",
        "../contracts/utility/FlowEVMBridgeHandlerInterfaces.cdc",
        args: []
    )

    deployWithArgs(
        "FlowEVMBridgeConfig",
        "../contracts/utility/FlowEVMBridgeConfig.cdc",
        args: []
    )

    deployWithArgs(
        "FlowEVMBridgeHandlers",
        "../contracts/utility/FlowEVMBridgeHandlers.cdc",
        args: []
    )

    deployWithArgs(
        "FiatToken",
        "../contracts/FiatToken.cdc",
        args: [
            VaultStoragePath,
            VaultBalancePubPath,
            VaultReceiverPubPath,
            //BlocklisterStoragePath,
            //PauserStoragePath,
            MinterStoragePath,
            tokenName,
            version,
            initTotalSupply
            //initPaused
        ]
    )
}

access(all)
fun testGetTotalSupply() {
    let scriptResult = executeScript(
        "../transactions/scripts/get_supply.cdc",
        []
    )
    Test.expect(scriptResult, Test.beSucceeded())

    let totalSupply = scriptResult.returnValue! as! UFix64
    Test.assertEqual(1000.00000000, totalSupply)
}

access(all)
fun testSetupAccount() {
    let txResult = executeTransaction(
        "../transactions/vault/create_vault.cdc",
        [],
        recipient
    )
    Test.expect(txResult, Test.beSucceeded())
}

access(all)
fun testMintTokens() {
    let txResult = executeTransaction(
        "../transactions/mint/mint.cdc",
        [recipient.address, 250.0],
        admin
    )
    Test.expect(txResult, Test.beSucceeded())

    // Test that the proper events were emitted
    var typ = Type<FiatToken.Mint>()
    var events = Test.eventsOfType(typ)
    Test.assertEqual(1, events.length)

    let tokensMintedEvent = events[0] as! FiatToken.Mint
    Test.assertEqual(250.0, tokensMintedEvent.amount)

    typ = Type<FungibleToken.Deposited>()
    let depositEvents = Test.eventsOfType(typ)

    let tokensDepositedEvent = depositEvents[depositEvents.length - 1] as! FungibleToken.Deposited
    Test.assertEqual(250.0, tokensDepositedEvent.amount)
    Test.assertEqual(recipient.address, tokensDepositedEvent.to!)
    Test.assertEqual("A.0000000000000007.FiatToken.Vault", tokensDepositedEvent.type)

    // Test that the totalSupply increased by the amount of minted tokens
    let scriptResult = executeScript(
        "../transactions/scripts/get_supply.cdc",
        []
    )
    Test.expect(scriptResult, Test.beSucceeded())

    let totalSupply = scriptResult.returnValue! as! UFix64
    Test.assertEqual(1250.0, totalSupply)
}

access(all)
fun testTransferTokens() {
    let txResult = executeTransaction(
        "../transactions/vault/transfer_FiatToken.cdc",
        [50.0, admin.address],
        recipient
    )
    Test.expect(txResult, Test.beSucceeded())

    var typ = Type<FungibleToken.Withdrawn>()
    let events = Test.eventsOfType(typ)

    let tokensWithdrawnEvent = events[events.length - 1] as! FungibleToken.Withdrawn
    Test.assertEqual(50.0, tokensWithdrawnEvent.amount)
    Test.assertEqual(recipient.address, tokensWithdrawnEvent.from!)

    var scriptResult = executeScript(
        "../transactions/scripts/get_balance.cdc",
        [recipient.address]
    )
    Test.expect(scriptResult, Test.beSucceeded())

    var balance = scriptResult.returnValue! as! UFix64
    // 250.0 tokens were previously minted to the recipient
    Test.assertEqual(200.0, balance)

    scriptResult = executeScript(
        "../transactions/scripts/get_balance.cdc",
        [admin.address]
    )
    Test.expect(scriptResult, Test.beSucceeded())

    // The admin had initially 1000.0 tokens (initial supply)
    balance = scriptResult.returnValue! as! UFix64
    Test.assertEqual(1050.0, balance)
}

access(all)
fun testVaultTypes() {
    let scriptResult = executeScript(
        "../transactions/scripts/get_views.cdc",
        [recipient.address]
    )
    Test.expect(scriptResult, Test.beSucceeded())

    let supportedViews = scriptResult.returnValue! as! [Type]
    let expectedViews = [
        Type<FungibleTokenMetadataViews.FTView>(),
        Type<FungibleTokenMetadataViews.FTDisplay>(),
        Type<FungibleTokenMetadataViews.FTVaultData>(),
        Type<FungibleTokenMetadataViews.TotalSupply>()
    ]
    Test.assertEqual(expectedViews, supportedViews)
}

// Not able to be fully tested until the bridge config is available on emulator
access(all)
fun testTransferMinterToBridge() {
    // var txResult = executeTransaction(
    //     "transactions/create_cadence_native_token_handler.cdc",
    //     ["A.0000000000000007.FiatToken.Vault", "A.0000000000000007.FiatToken.MinterResource"],
    //     admin
    // )
    // Test.expect(txResult, Test.beSucceeded())

    // txResult = executeTransaction(
    //     "transactions/enable_token_handler.cdc",
    //     ["A.0000000000000007.FiatToken.Vault"],
    //     admin
    // )
    // Test.expect(txResult, Test.beSucceeded())

    // deployWithArgs(
    //     "FiatTokenMinterToBridge",
    //     "../contracts/FiatTokenMinterToBridge.cdc",
    //     args: [
    //         admin.address
    //     ]
    // )
}