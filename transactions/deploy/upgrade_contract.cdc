import FiatToken from 0x{{.FiatToken}}
// This transactions upgrades the FiatToken contract with a resource
//
// Admin (AuthAccount) of this script is the owner of the contract
//
transaction(
    contractName: String, 
    code: String,
    version: String
) {
    prepare(admin: AuthAccount) {
        // get a reference to the account's Admin
        let a = admin.borrow<&FiatToken.Admin>(from: FiatToken.AdminStoragePath) 
            ?? panic ("no admin resource avaialble");

        a.upgradeContract(name: contractName, code: code.decodeHex(), version: version);
    }
}
