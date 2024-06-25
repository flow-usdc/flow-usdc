package main

import (
	//if you imports this with .  you do not have to repeat overflow everywhere
	. "github.com/bjartek/overflow/v2"
)

func main() {

	// start an in memory emulator by default
	// there are two interfaces published for Overflow, `OverflowClient` and `OverrflowBetaClient` that has unstable api, I urge you to store this as the client and not the impl. Currenly the Overflow method returns the impl so you can choose.
	o := Overflow()

	//the Tx DSL runs an transaction
	o.Tx("name_of_transaction", SignProposeAndPayAs("bob"), Arg("name", "bob")).Print()

	//Run a script/get interaction against the same in memory chain
	o.Script("name_of_script", Arg("name", "bob")).Print()
}
