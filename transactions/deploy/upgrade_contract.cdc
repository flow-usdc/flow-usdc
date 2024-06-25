import "FiatToken"
// This transactions upgrades the FiatToken contract with a resource
//
// Admin (auth(BorrowValue) &Account) of this script is the owner of the contract
//
transaction(
    contractName: String, 
    code: String,
    version: String
) {
    prepare(admin: auth(BorrowValue) &Account) {
        // get a reference to the account's Admin
        let a = admin.storage.borrow<&FiatToken.Admin>(from: FiatToken.AdminStoragePath) 
            ?? panic ("no admin resource avaialble");

        a.upgradeContract(name: contractName, code: code.decodeHex(), version: version);
    }
}
