// remove contract 

import FiatToken from 0x{{.FiatToken}}

transaction (name: String) {
    prepare(owner: AuthAccount) {
        owner.contracts.remove(name: name)
    }
}
