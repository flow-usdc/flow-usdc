// remove contract 

import "FiatToken"

transaction (name: String) {
    prepare(owner: auth(Contracts) &Account) {
        owner.contracts.remove(name: name)
    }
}
