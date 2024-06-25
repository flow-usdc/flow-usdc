import Test
import BlockchainHelpers
import "test_helpers.cdc"
import "FungibleToken"
//import "FungibleTokenMetadataViews"
import "FiatToken"
import Crypto

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let recipient = Test.createAccount()

access(all) let VaultStoragePath = StoragePath(identifier: "USDCVault")!
access(all) let VaultBalancePubPath = PublicPath(identifier: "USDCVaultBalance")!
access(all) let VaultReceiverPubPath = PublicPath(identifier: "USDCVaultReceiver")!
access(all) let VaultUUIDPubPath = PublicPath(identifier: "USDCVaultUUID")!

access(all) let BlocklistExecutorStoragePath = StoragePath(identifier: "USDCBlocklistExe")!
access(all) let BlocklisterStoragePath = StoragePath(identifier: "USDCBlocklister")!
access(all) let BlocklisterCapReceiverPubPath = PublicPath(identifier: "USDCBlocklisterCapReceiver")!
access(all) let BlocklisterUUIDPubPath = PublicPath(identifier: "USDCBlocklisterUUID")!
access(all) let BlocklisterPubSigner = PublicPath(identifier: "USDCBlocklisterPublicSigner")!

access(all) let PauseExecutorStoragePath = StoragePath(identifier: "USDCPauseExe")!
access(all) let PauserStoragePath = StoragePath(identifier: "USDCPauser")!
access(all) let PauserCapReceiverPubPath = PublicPath(identifier: "USDCPauserCapReceiver")!
access(all) let PauserUUIDPubPath = PublicPath(identifier: "USDCPauserUUID")!
access(all) let PauserPubSigner = PublicPath(identifier: "USDCPauserPublicSigner")!

access(all) let AdminExecutorStoragePath = StoragePath(identifier: "USDCAdminExe")!
access(all) let AdminStoragePath = StoragePath(identifier: "USDCAdmin")!
access(all) let AdminCapReceiverPubPath = PublicPath(identifier: "USDCAdminCapReceiver")!
access(all) let AdminUUIDPubPath = PublicPath(identifier: "USDCAdminUUID")!
access(all) let AdminPubSigner = PublicPath(identifier: "USDCAdminPublicSigner")!

access(all) let OwnerExecutorStoragePath = StoragePath(identifier: "USDCOwnerExe")!
access(all) let OwnerStoragePath = StoragePath(identifier: "USDCOwner")!
access(all) let OwnerCapReceiverPubPath = PublicPath(identifier: "USDCOwnerCapReceiver")!
access(all) let OwnerUUIDPubPath = PublicPath(identifier: "USDCOwnerUUID")!
access(all) let OwnerPubSigner = PublicPath(identifier: "USDCOwnerPubSigner")!

access(all) let MasterMinterExecutorStoragePath = StoragePath(identifier: "USDCMasterMinterExe")!
access(all) let MasterMinterStoragePath = StoragePath(identifier: "USDCMasterMinter")!
access(all) let MasterMinterCapReceiverPubPath = PublicPath(identifier: "USDCMasterMinterCapReceiver")!
access(all) let MasterMinterPubSigner = PublicPath(identifier: "USDCMasterMinterPublicSigner")!
access(all) let MasterMinterUUIDPubPath = PublicPath(identifier: "USDCMasterMinterUUID")!

access(all) let MinterControllerStoragePath = StoragePath(identifier: "USDCMinterController")!
access(all) let MinterControllerUUIDPubPath = PublicPath(identifier: "USDCMinterControllerUUID")!
access(all) let MinterControllerPubSigner = PublicPath(identifier: "USDCMinterControllerPublicSigner")!

access(all) let MinterStoragePath = StoragePath(identifier: "USDCMinter")!
access(all) let MinterUUIDPubPath = PublicPath(identifier: "USDCMinterUUID")!

access(all) let tokenName = "USDC"
access(all) let version = "2.0.0"
access(all) let initTotalSupply = 1000.0
access(all) let initPaused = false

access(all) let adminPubKeys: [String] = []
access(all) let adminPubKeysWeights: [UFix64] = []
access(all) let adminPubKeysAlgos: [UInt8] = []
access(all) let ownerPubKeys: [String] = []
access(all) let ownerPubKeysWeights: [UFix64] = []
access(all) let ownerPubKeysAlgos: [UInt8] = []
access(all) let masterMinterPubKeys: [String] = []
access(all) let masterMinterPubKeysWeights: [UFix64] = []
access(all) let masterMinterPubKeysAlgos: [UInt8] = []
access(all) let blocklisterPubKeys: [String] = []
access(all) let blocklisterPubKeysWeights: [UFix64] = []
access(all) let blocklisterPubKeysAlgos: [UInt8] = []
access(all) let pauserPubKeys: [String] = []
access(all) let pauserPubKeysWeights: [UFix64] = []
access(all) let pauserPubKeysAlgos: [UInt8] = []

access(all)
fun setup() {
    deployWithArgs(
        "IBridgePermissions",
        "../contracts/utility/IBridgePermissions.cdc",
        args: []
    )

    deployWithArgs(
        "OnChainMultiSig",
        "../contracts/OnChainMultiSig.cdc",
        args: []
    )

    deployWithArgs(
        "FiatToken",
        "../contracts/FiatToken.cdc",
        args: [
            // VaultStoragePath,
            // VaultBalancePubPath,
            // VaultReceiverPubPath,
            // VaultUUIDPubPath,
            // BlocklistExecutorStoragePath,
            // BlocklisterStoragePath,
            // BlocklisterCapReceiverPubPath,
            // BlocklisterUUIDPubPath,
            // BlocklisterPubSigner,
            // PauseExecutorStoragePath,
            // PauserStoragePath,
            // PauserCapReceiverPubPath,
            // PauserUUIDPubPath,
            // PauserPubSigner,
            // AdminExecutorStoragePath,
            // AdminStoragePath,
            // AdminCapReceiverPubPath,
            // AdminUUIDPubPath,
            // AdminPubSigner,
            // OwnerExecutorStoragePath,
            // OwnerStoragePath,
            // OwnerCapReceiverPubPath,
            // OwnerUUIDPubPath,
            // OwnerPubSigner,
            // MasterMinterExecutorStoragePath,
            // MasterMinterStoragePath,
            // MasterMinterCapReceiverPubPath,
            // MasterMinterPubSigner,
            // MasterMinterUUIDPubPath,
            // MinterControllerStoragePath,
            // MinterControllerUUIDPubPath,
            // MinterControllerPubSigner,
            // MinterStoragePath,
            // MinterUUIDPubPath,
            // tokenName,
            // version,
            // initTotalSupply,
            // initPaused,
            adminPubKeys,
            adminPubKeysWeights,
            adminPubKeysAlgos,
            ownerPubKeys,
            ownerPubKeysWeights,
            ownerPubKeysAlgos,
            masterMinterPubKeys,
            masterMinterPubKeysWeights,
            masterMinterPubKeysAlgos,
            blocklisterPubKeys,
            blocklisterPubKeysWeights,
            blocklisterPubKeysAlgos,
            pauserPubKeys,
            pauserPubKeysWeights,
            pauserPubKeysAlgos
        ]
    )
}

access(all)
fun testGetTotalSupply() {
    let scriptResult = executeScript(
        "../scripts/contract/get_total_supply.cdc",
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
        [250.0, recipient.address],
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
        "../scripts/contract/get_total_supply.cdc",
        []
    )
    Test.expect(scriptResult, Test.beSucceeded())

    let totalSupply = scriptResult.returnValue! as! UFix64
    Test.assertEqual(1250.0, totalSupply)
}

// access(all)
// fun testTransferTokens() {
//     let txResult = executeTransaction(
//         "../transactions/vault/transfer_FiatToken.cdc",
//         [50.0, admin.address],
//         recipient
//     )
//     Test.expect(txResult, Test.beSucceeded())

//     var typ = Type<FungibleToken.Withdrawn>()
//     let events = Test.eventsOfType(typ)

//     let tokensWithdrawnEvent = events[events.length - 1] as! FungibleToken.Withdrawn
//     Test.assertEqual(50.0, tokensWithdrawnEvent.amount)
//     Test.assertEqual(recipient.address, tokensWithdrawnEvent.from!)

//     var scriptResult = executeScript(
//         "../transactions/scripts/get_balance.cdc",
//         [recipient.address]
//     )
//     Test.expect(scriptResult, Test.beSucceeded())

//     var balance = scriptResult.returnValue! as! UFix64
//     // 250.0 tokens were previously minted to the recipient
//     Test.assertEqual(200.0, balance)

//     scriptResult = executeScript(
//         "../transactions/scripts/get_balance.cdc",
//         [admin.address]
//     )
//     Test.expect(scriptResult, Test.beSucceeded())

//     // The admin had initially 1000.0 tokens (initial supply)
//     balance = scriptResult.returnValue! as! UFix64
//     Test.assertEqual(1050.0, balance)
// }

// access(all)
// fun testVaultTypes() {
//     let scriptResult = executeScript(
//         "../transactions/scripts/get_views.cdc",
//         [recipient.address]
//     )
//     Test.expect(scriptResult, Test.beSucceeded())

//     let supportedViews = scriptResult.returnValue! as! [Type]
//     let expectedViews = [
//         Type<FungibleTokenMetadataViews.FTView>(),
//         Type<FungibleTokenMetadataViews.FTDisplay>(),
//         Type<FungibleTokenMetadataViews.FTVaultData>(),
//         Type<FungibleTokenMetadataViews.TotalSupply>()
//     ]
//     Test.assertEqual(expectedViews, supportedViews)
// }

// access(all)
// fun testAddServiceAccountKey() {

//     var txResult = executeTransaction(
//         "../transactions/admin/add_service_key.cdc",
//         [],
//         recipient
//     )
//     Test.expect(txResult, Test.beSucceeded())

//     txResult = executeTransaction(
//         "../transactions/admin/add_service_key.cdc",
//         [],
//         recipient
//     )
//     Test.expect(txResult, Test.beFailed())

// }