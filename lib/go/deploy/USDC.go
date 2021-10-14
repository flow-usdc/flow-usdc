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

	multiSigPubKeys, multiSigKeyWeights, multiSigAlgos := util.GetMultiSigKeys(g)

	e, err := g.TransactionFromFile(txFilename, code).
		SignProposeAndPayAs(ownerAcct).
		StringArgument("FiatToken").
		StringArgument(encodedStr).
		// Vault
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCVault-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCVaultProvider-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultBalance-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultAllowance-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultPublicSigner-2"}).
		// Blocklist executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCBlocklistExe-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCBlocklistExeCap-2"}).
		// Blocklister
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCBlocklister-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterPublicSigner-2"}).
		// Pause executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPauseExe-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCPauseExeCap-2"}).
		// Pauser
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPauser-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserPublicSigner-2"}).
		//Admine
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCAdmin-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCAdminPublicSigner-2"}).
		// Owner
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCOwner-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCOwnerCap-2"}).
		// Masterminter
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMasterMinter-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCMasterMinterCap-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterPublicSigner-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterUUID-2"}).
		// Minter Controller
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMinterController-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterControllerUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterControllerPublicSigner-2"}).
		// Minter
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMinter-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterPublicSigner-2"}).
		StringArgument(tokenName).
		StringArgument(version).
		UFix64Argument("1000000000.00000000").
		BooleanArgument(false).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		Argument(cadence.NewArray(multiSigAlgos)).
		RunE()
	gwtf.PrintEvents(e, map[string][]string{})
	events = util.ParseTestEvents(e)

	return
}

func UpgradeFiatTokenContract(
	g *gwtf.GoWithTheFlow,
	ownerAcct string, version string) (events []*gwtf.FormatedEvent, err error) {
	contractCode := util.ParseCadenceTemplate("../../../contracts/FiatToken.cdc")
	txFilename := "../../../transactions/deploy/upgrade_contract.cdc"
	code := util.ParseCadenceTemplate(txFilename)
	encodedStr := hex.EncodeToString(contractCode)

	e, err := g.TransactionFromFile(txFilename, code).
		SignProposeAndPayAs(ownerAcct).
		StringArgument("FiatToken").
		StringArgument(encodedStr).
		StringArgument(version).
		RunE()
	gwtf.PrintEvents(e, map[string][]string{})
	events = util.ParseTestEvents(e)

	return
}
