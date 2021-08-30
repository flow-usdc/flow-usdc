package deploy

import (
	"encoding/hex"

	util "github.com/flow-usdc/flow-usdc"
	"github.com/onflow/cadence"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func DeployFiatTokenContract(
	g *gwtf.GoWithTheFlow,
	ownerAcct string, tokenName string, version string) (events []*gwtf.FormatedEvent, err error) {
	contractCode := util.ParseCadenceTemplate("../../contracts/FiatToken.cdc")
	txFilename := "../../transactions/deploy/deploy_contract_with_auth.cdc"
	code := util.ParseCadenceTemplate(txFilename)
	encodedStr := hex.EncodeToString(contractCode)

	if g.Network == "emulator" {
		g.CreateAccounts("emulator-account")
	}

	multiSigPubKeys, multiSigKeyWeights := util.GetMultiSigKeys(g)

	e, err := g.TransactionFromFile(txFilename, code).
		SignProposeAndPayAs(ownerAcct).
		StringArgument("FiatToken").
		StringArgument(encodedStr).
		// Vault
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCVault"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultBalance"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultUUID"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultAllowance"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultReceiver"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultPublicSigner"}).
		// Blocklist executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCBlocklistExe"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCBlocklistExeCap"}).
		// Blocklister
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCBlocklister"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterCapReceiver"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterPublicSigner"}).
		// Pause executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPauseExe"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCPauseExeCap"}).
		// Pauser
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPauser"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserCapReceiver"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserPublicSigner"}).
		// Owner
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCOwner"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCOwnerCap"}).
		// Masterminter
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMasterMinter"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCMasterMinterCap"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterPublicSigner"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterUUID"}).
		// Minter Controller
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMinterController"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterControllerUUID"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterControllerPublicSigner"}).
		// Minter
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMinter"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterUUID"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterPublicSigner"}).
		StringArgument(tokenName).
		StringArgument(version).
		UFix64Argument("1000000000.00000000").
		BooleanArgument(false).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		RunE()
	gwtf.PrintEvents(e, map[string][]string{})
	events = util.ParseTestEvents(e)

	return
}
