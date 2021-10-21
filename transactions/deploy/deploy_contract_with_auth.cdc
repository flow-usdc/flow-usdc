// This transactions deploys the FiatToken contract
//
// Owner (AuthAccount) of this script is the owner of the contract
//
transaction(
    contractName: String, 
    code: String,
    VaultStoragePath: StoragePath,
    VaultBalancePubPath: PublicPath,
    VaultUUIDPubPath: PublicPath,
    VaultAllowancePubPath: PublicPath,
    VaultReceiverPubPath: PublicPath,
    VaultPubSigner: PublicPath,
    BlocklistExecutorStoragePath: StoragePath,
    BlocklisterStoragePath: StoragePath,
    BlocklisterCapReceiverPubPath: PublicPath,
    BlocklisterPubSigner: PublicPath,
    PauseExecutorStoragePath: StoragePath,
    PauserStoragePath: StoragePath,
    PauserCapReceiverPubPath: PublicPath,
    PauserPubSigner: PublicPath,
    AdminExecutorStoragePath: StoragePath,
    AdminStoragePath: StoragePath,
    AdminCapReceiverPubPath: PublicPath,
    AdminUUIDPubPath: PublicPath,
    AdminPubSigner: PublicPath,
    OwnerExecutorStoragePath: StoragePath,
    OwnerStoragePath: StoragePath,
    OwnerCapReceiverPubPath: PublicPath,
    OwnerPubSigner: PublicPath,
    MasterMinterExecutorStoragePath: StoragePath,
    MasterMinterStoragePath: StoragePath,
    MasterMinterCapReceiverPubPath: PublicPath,
    MasterMinterPubSigner: PublicPath,
    MasterMinterUUIDPubPath: PublicPath,
    MinterControllerStoragePath: StoragePath,
    MinterControllerUUIDPubPath: PublicPath,
    MinterControllerPubSigner: PublicPath,
    MinterStoragePath: StoragePath,
    MinterUUIDPubPath: PublicPath,
    MinterPubSigner: PublicPath,
    initialAdminCapabilityPrivPath: PrivatePath,
    initialOwnerCapabilityPrivPath: PrivatePath,
    initialMasterMinterCapabilityPrivPath: PrivatePath,
    initialPauserCapabilityPrivPath: PrivatePath,
    initialBlocklisterCapabilityPrivPath: PrivatePath,
    tokenName: String,
    version: String,
    initTotalSupply: UFix64,
    initPaused: Bool,
    ownerAccountPubKeys: [String],
    ownerAccountKeyWeights: [UFix64],
    ownerAccountKeyAlgos : [UInt8],
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
                VaultPubSigner: VaultPubSigner,
                BlocklistExecutorStoragePath: BlocklistExecutorStoragePath,
                BlocklisterStoragePath: BlocklisterStoragePath,
                BlocklisterCapReceiverPubPath: BlocklisterCapReceiverPubPath,
                BlocklisterPubSigner: BlocklisterPubSigner,
                PauseExecutorStoragePath: PauseExecutorStoragePath,
                PauserStoragePath: PauserStoragePath,
                PauserCapReceiverPubPath: PauserCapReceiverPubPath,
                PauserPubSigner: PauserPubSigner,
                AdminExecutorStoragePath: AdminExecutorStoragePath,
                AdminStoragePath: AdminStoragePath,
                AdminCapReceiverPubPath: AdminCapReceiverPubPath,
                AdminUUIDPubPath: AdminUUIDPubPath,
                AdminPubSigner: AdminPubSigner,
                OwnerExecutorStoragePath: OwnerExecutorStoragePath,
                OwnerStoragePath: OwnerStoragePath,
                OwnerCapReceiverPubPath: OwnerCapReceiverPubPath,
                OwnerPubSigner: OwnerPubSigner,
                MasterMinterExecutorStoragePath: MasterMinterExecutorStoragePath,
                MasterMinterStoragePath: MasterMinterStoragePath,
                MasterMinterCapReceiverPubPath: MasterMinterCapReceiverPubPath,
                MasterMinterPubSigner: MasterMinterPubSigner,
                MasterMinterUUIDPubPath: MasterMinterUUIDPubPath,
                MinterControllerStoragePath:  MinterControllerStoragePath,
                MinterControllerUUIDPubPath: MinterControllerUUIDPubPath,
                MinterControllerPubSigner: MinterControllerPubSigner,
                MinterStoragePath: MinterStoragePath,
                MinterUUIDPubPath: MinterUUIDPubPath,
                MinterPubSigner: MinterPubSigner,
                initialAdminCapabilityPrivPath: initialAdminCapabilityPrivPath,
                initialOwnerCapabilityPrivPath: initialOwnerCapabilityPrivPath,
                initialMasterMinterCapabilityPrivPath: initialMasterMinterCapabilityPrivPath,
                initialPauserCapabilityPrivPath: initialPauserCapabilityPrivPath,
                initialBlocklisterCapabilityPrivPath: initialBlocklisterCapabilityPrivPath,
                tokenName: tokenName,
                version: version,
                initTotalSupply: initTotalSupply,
                initPaused: initPaused, 
                ownerAccountPubKeys: ownerAccountPubKeys,
                ownerAccountKeyWeights: ownerAccountKeyWeights,
                ownerAccountKeyAlgos: ownerAccountKeyAlgos,
            )
        } else {
            owner.contracts.update__experimental(name: contractName, code: code.decodeHex())
        }
    }
}
