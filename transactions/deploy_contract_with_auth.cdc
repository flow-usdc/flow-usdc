// This transactions deploys the USDC contract
//
// Owner of the contract has exclusive functions
// We only provide the AuthAccount holder the owner resource
//
transaction(contractName: String, code: String) {
    prepare(owner: AuthAccount) {
        let existingContract = owner.contracts.get(name: contractName)

        if (existingContract == nil) {
            owner.contracts.add(name: contractName, code: code.decodeHex(), owner)
        } else {
            owner.contracts.update__experimental(name: contractName, code: code.decodeHex())
        }
    }
}
