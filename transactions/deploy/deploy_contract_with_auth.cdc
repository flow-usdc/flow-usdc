// This transactions deploys the FiatToken contract
//
// Owner of the contract has exclusive functions
// We only provide the AuthAccount holder the owner resource
//
transaction(
    contractName: String, 
    code: String,
    VaultStoragePath: StoragePath,
    VaultBalancePubPath: PublicPath,
    VaultUUIDPubPath: PublicPath,
    VaultAllowancePubPath: PublicPath,
    VaultReceiverPubPath: PublicPath,
    BlocklistExecutorStoragePath: StoragePath,
    BlocklistExecutorPrivPath: PrivatePath,
    BlocklisterStoragePath: StoragePath,
    BlocklisterCapReceiverPubPath: PublicPath,
    PauseExecutorStoragePath: StoragePath,
    PauseExecutorPrivPath: PrivatePath,
    PauserStoragePath: StoragePath,
    PauserCapReceiverPubPath: PublicPath,
    OwnerStoragePath: StoragePath,
    OwnerPrivPath: PrivatePath,
    MasterMinterStoragePath: StoragePath,
    MasterMinterPrivPath: PrivatePath,
    MasterMinterPubSigner: PublicPath,
    MasterMinterUUIDPubPath: PublicPath,
    MinterControllerStoragePath: StoragePath,
    MinterControllerUUIDPubPath: PublicPath,
    MinterStoragePath: StoragePath,
    MinterUUIDPubPath: PublicPath,
    MinterPubSigner: PublicPath,
    tokenName: String,
    initTotalSupply: UFix64,
    initPaused: Bool,
    ownerAccountPubKeys: [String],
    ownerAccountKeyWeights: [UFix64],
) {
    prepare(owner: AuthAccount) {
        let existingContract = owner.contracts.get(name: contractName)

        if (existingContract == nil) {
            owner.contracts.add(
                name: contractName, 
                code: code.decodeHex(), 
                owner,
                VaultStoragePath: VaultStoragePath,
                VaultBalancePubPath: VaultBalancePubPath,
                VaultUUIDPubPath: VaultUUIDPubPath,
                VaultAllowancePubPath: VaultAllowancePubPath,
                VaultReceiverPubPath: VaultReceiverPubPath,
                BlocklistExecutorStoragePath: BlocklistExecutorStoragePath,
                BlocklistExecutorPrivPath: BlocklistExecutorPrivPath,
                BlocklisterStoragePath: BlocklisterStoragePath,
                BlocklisterCapReceiverPubPath: BlocklisterCapReceiverPubPath,
                PauseExecutorStoragePath: PauseExecutorStoragePath, 
                PauseExecutorPrivPath: PauseExecutorPrivPath,
                PauserStoragePath: PauserStoragePath,
                PauserCapReceiverPubPath: PauserCapReceiverPubPath,
                OwnerStoragePath: OwnerStoragePath,
                OwnerPrivPath: OwnerPrivPath,
                MasterMinterStoragePath: MasterMinterStoragePath,
                MasterMinterPrivPath: MasterMinterPrivPath,
                MasterMinterPubSigner: MasterMinterPubSigner,
                MasterMinterUUIDPubPath: MasterMinterUUIDPubPath,
                MinterControllerStoragePath:  MinterControllerStoragePath,
                MinterControllerUUIDPubPath: MinterControllerUUIDPubPath,
                MinterStoragePath: MinterStoragePath,
                MinterUUIDPubPath: MinterUUIDPubPath,
                MinterPubSigner: MinterPubSigner,
                tokenName: tokenName,
                initTotalSupply: initTotalSupply,
                initPaused: initPaused, 
                ownerAccountPubKeys: ownerAccountPubKeys,
                ownerAccountKeyWeights: ownerAccountKeyWeights,
            )
        } else {
            owner.contracts.update__experimental(name: contractName, code: code.decodeHex())
        }
    }
}
