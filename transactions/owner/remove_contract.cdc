// remove contract 

import FiatToken from 0x{{.FiatToken}}
import FiatTokenInterface from 0x{{.FiatTokenInterface}}

transaction (name: String) {
    prepare(owner: AuthAccount) {
        owner.contracts.remove(name: name)
    }
}
