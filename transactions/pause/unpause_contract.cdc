// This unpauses the contract by a Pauser if capability was granted

import "FiatToken"

transaction {
    prepare (pauser: auth(BorrowValue) &Account) {

        let pauser = pauser.storage.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) ?? panic("cannot borrow own private path")
        pauser.unpause();
    } 

    post {
        !FiatToken.paused: "unpause contract error"
    }
}
