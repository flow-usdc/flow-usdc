// This transactions removes the USDC contract

import USDC from 0x{{.USDCToken}}

transaction(contractName: String) {
    prepare(owner: AuthAccount) {
        owner.unlink(USDC.MasterMinterPrivPath)
        owner.unlink(USDC.BlockListExecutorPrivPath)
        owner.unlink(USDC.PauseExecutorPrivPath)

        destroy owner.load<@USDC.MasterMinter>(from: USDC.MasterMinterStoragePath)
        destroy owner.load<@USDC.BlockListExecutor>(from: USDC.BlockListExecutorStoragePath)
        destroy owner.load<@USDC.PauseExecutor>(from: /storage/UsdcPauseExec)
        destroy owner.load<@USDC.Pauser>(from: /storage/UsdcPauseExec)

        owner.unlink(USDC.OwnerPrivPath)

        destroy owner.load<@USDC.Owner>(from: USDC.OwnerStoragePath)

        owner.unlink(/public/UsdcReceiver)
        owner.unlink(/public/UsdcBalance)

        destroy owner.load<@USDC.Vault>(from: /storage/UsdcVault)

        owner.contracts.remove(name: contractName)
    }
}
