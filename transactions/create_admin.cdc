import FungibleToken from 0x{{.FungibleToken}}
import ExampleToken from 0x{{.ExampleToken}}

transaction() {
    let tokenAdmin: &ExampleToken.Administrator

    prepare(admin: AuthAccount, newAdmin: AuthAccount) {
        self.tokenAdmin = admin.borrow<&ExampleToken.Administrator>(from: /storage/exampleTokenAdmin)
            ?? panic("Signer is not the token admin")

        if newAdmin.borrow<&ExampleToken.Administrator>(from: /storage/exampleTokenAdmin) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        newAdmin.save(
            <-ExampleToken.createNewAdministrator(),
            to: /storage/exampleTokenAdmin
        )
    }
}
