// This transactions deploys the USDC contract
//
// Owner of the contract has exclusive functions
// We only provide the AuthAccount holder the owner resource
// Current, the deployer is the owner of the contract
//
transaction(contractName: String, code: String) {
    prepare(owner: AuthAccount) {
        owner.contracts.add(name: contractName, code: code.decodeHex(), owner)
    }
}

