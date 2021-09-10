#!/bin/bash
source .env

# using go scripts due to https://github.com/onflow/flow-cli/issues/373
# this issue is now fixed
cd lib/go/scripts
go run ./testnet-create-accounts/create_accounts.go allowance
go run ./testnet-create-accounts/create_accounts.go blocklister
go run ./testnet-create-accounts/create_accounts.go minter 
go run ./testnet-create-accounts/create_accounts.go minterController1 
go run ./testnet-create-accounts/create_accounts.go minterController2
go run ./testnet-create-accounts/create_accounts.go non-allowance
go run ./testnet-create-accounts/create_accounts.go non-blocklister
go run ./testnet-create-accounts/create_accounts.go non-minter
go run ./testnet-create-accounts/create_accounts.go non-multisig-account
go run ./testnet-create-accounts/create_accounts.go non-pauser
go run ./testnet-create-accounts/create_accounts.go non-vaulted-account
go run ./testnet-create-accounts/create_accounts.go pauser
go run ./testnet-create-accounts/create_accounts.go vaulted-account
go run ./testnet-create-accounts/create_accounts.go w-1000
go run ./testnet-create-accounts/create_accounts.go w-250-1
go run ./testnet-create-accounts/create_accounts.go w-250-2
go run ./testnet-create-accounts/create_accounts.go w-500-1
go run ./testnet-create-accounts/create_accounts.go w-500-2

# Transaction rec
# 2021/08/30 11:11:02 getting key:  allowance
# 2021/08/30 11:11:02 key:  testnet-allowance
# 2021/08/30 11:11:02 pubkey 0xab84660c9ae7da9d0d664cb3adaee657223341df46ce1f077c031961ec12d5fc2283c7bd5d375e00f63fc03ea22fdb91a7e0c31c94c263dc05dd6addf320cbb8
# 2021/08/30 11:11:02 getting key:  owner
# 2021/08/30 11:11:02 key:  testnet-owner
# Transaction ID: 3c8c29effb1aabc9057319315a679e9cd1a0e4dc9030d656d0c48acd313ed8b9
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# ./testnet-create-accounts.sh
# 2021/08/30 11:32:34 network:  testnet
# 2021/08/30 11:32:34 ---------
# 2021/08/30 11:32:34
# 2021/08/30 11:32:34
# 2021/08/30 11:32:34 account:  blocklister
# {9a0766d93b6608b7    }
# 2021/08/30 11:32:34 getting key:  blocklister
# 2021/08/30 11:32:34 key:  testnet-blocklister
# 2021/08/30 11:32:34 getting key:  owner
# 2021/08/30 11:32:34 key:  testnet-owner
# Transaction ID: d71bd7563f8f037e4fee443291d119a1c2632dca5cc9fc713b149cc0472d93c2
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:32:47 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x0db9375d7fe7204f25eb8182603005284558f6ddbf91c8aee1f7618dd1ec52ab A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x20beabb1e6bf445be9c6de8f5eab7ae01a0a05d1cb32b1f961448bd6e0d36ed2 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xea89b2b4fe9727e70908c65685a532a7bd7b2dec8eb1660e4de7403b3aaaf913 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x18d77f100f1f3610cb004b283705bce85bb235686110191b1509529770ad3053 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x3b61cc736a4d46150304f7c53f95505fa92bdf464b9d68a7fd026606ab281a1c flow.AccountCreated: 0x167202b38cf6ee84356b10169c90778dd06a155b4e412657e0de0b59c9a9afaa flow.AccountKeyAdded: 0x6207ad2a9f3a3f7ee034d3ce9248914c9a2f0f44f5c922931ff35257e3c51dd6 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x594378bd836e3e3ebf2a3a3bdfb5626fc3a8032b2186b6fcf52cada9d3b5b398 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xb65cb47cb3c85f4f6ce8eab91965d74997f35fdd92fb771bb0b2d62c998cba8e A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x4d7451416eefcd5a863a04c862c4bda02a040b5513a7c227eabbbee12f841a8f]
# 2021/08/30 11:32:47
# 2021/08/30 11:32:47
# 2021/08/30 11:32:47 ---------
# 2021/08/30 11:32:50 network:  testnet
# 2021/08/30 11:32:50 ---------
# 2021/08/30 11:32:50
# 2021/08/30 11:32:50
# 2021/08/30 11:32:50 account:  minter
# {9a0766d93b6608b7    }
# 2021/08/30 11:32:50 getting key:  minter
# 2021/08/30 11:32:50 key:  testnet-minter
# 2021/08/30 11:32:50 getting key:  owner
# 2021/08/30 11:32:50 key:  testnet-owner
# Transaction ID: 76ccd34d55567b7b17d1c4ef48e39fa70e94f4a2f96f1850f40a6ba7ee0e41b2
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:33:03 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x445461e397074cfce1a8f687133e077ee019d99dd6bdedb2853d6c5b51ec170f A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xc4f45d8d5e971c5633bc6ec39f843a1ae2bdb60d7e2e2912a553654ff598bc0a A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x524c89074c31e20e5f0de51c6cf31394c10456ccebfd0b66dce13de2f6031c58 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x83dd57fc05eb795f3b7ca7476515b57538b47a1166c0dca8fb40ce933bf36cba A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x63ed57b1cafeed470f8320ae4a78dc8c98bf5c8c0e77b534d855ecfa22c865b2 flow.AccountCreated: 0x358dd2a21954855aa9f5fc4e9c8187bfebc4ba352caa3b4dc19ea81c21e5f10a flow.AccountKeyAdded: 0x92ecb09475cacfcaf38f3b129e2c7438da92789662f315e57787f5794ec4fa3a A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x84f84ded769e86aff5951cc8de7ad5550e3839435684ba59dea841cf0628e5c4 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x9d39eaf64f1b9de1fd5f84dc1996192376245f2ca57160952d26b6adf20ffb78 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xf5053a59946f15be13e79222e46cc364ba7020359b60e4df621c44a3f3981856]
# 2021/08/30 11:33:03
# 2021/08/30 11:33:03
# 2021/08/30 11:33:03 ---------
# 2021/08/30 11:33:06 network:  testnet
# 2021/08/30 11:33:06 ---------
# 2021/08/30 11:33:06
# 2021/08/30 11:33:06
# 2021/08/30 11:33:06 account:  minterController1
# {9a0766d93b6608b7    }
# 2021/08/30 11:33:06 getting key:  minterController1
# 2021/08/30 11:33:06 key:  testnet-minterController1
# 2021/08/30 11:33:06 getting key:  owner
# 2021/08/30 11:33:06 key:  testnet-owner
# Transaction ID: a5063a6b8d8bd2cc70ff27835d195dc36cd0658028cef7eeefc64194b624dcdb
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:33:20 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x7e7a0e24656da5e3fcab98825558944756f524e95ba07306ead7863755126e4f A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xd01b16f3b15738f3ebe860e8f9f892105ade3c6f19e8ea2774df6d7e5c89e2b5 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xc55a5493b85002c6251cd95898691ce16691a994e82cc603a44edae247254255 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x0cea7a42514d8896027e9dec430a067bf4889b90a2ab30706dd7551fb01c9de2 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x8c7c1c8e8cec9619445241ee445ba7912cd57203c4efa4885f0d75fd909d3652 flow.AccountCreated: 0x1cf86636cfb5e663907764596bfc2a2d178399629d22fd8997b39aeb79af4996 flow.AccountKeyAdded: 0xaf1208aadf8a3ec34105ec2495c9f59191d820591a86a2e17abc907513deb747 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xb7ac1eb4c87dc315cd5b339626a2eae03b1d61b67258697e233d38037669045b A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x477a6684babc7f07d17ea33981621faa805506311ef950bc17e571880bb1bef3 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xabf18c92393bbc6bc8909e48adc9ef436f0641aa3a80176680e3ef1015d80117]
# 2021/08/30 11:33:20
# 2021/08/30 11:33:20
# 2021/08/30 11:33:20 ---------
# 2021/08/30 11:33:22 network:  testnet
# 2021/08/30 11:33:22 ---------
# 2021/08/30 11:33:22
# 2021/08/30 11:33:22
# 2021/08/30 11:33:22 account:  minterController2
# {9a0766d93b6608b7    }
# 2021/08/30 11:33:22 getting key:  minterController2
# 2021/08/30 11:33:22 key:  testnet-minterController2
# 2021/08/30 11:33:22 getting key:  owner
# 2021/08/30 11:33:22 key:  testnet-owner
# Transaction ID: dba2d2c19d2e07c3444acceeb480f92eb47fedc906c0e6a9df68afa67626eaa3
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:33:36 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x6ef3beb9b2adf40bed1aea9fa5ec1dfa3b16b9472c367eb9cd15d8da44cc5c12 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x146fa8991a063925438d984e182cd9f0edde5c78183113d841b34256a79174e7 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x03f87113ce9a069843c152072af2565f10ff3cc70dd2b8e1c12c4280346e985d A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x0bd79497c7daa49c2da8c063a9bf2e1361e2ab44e69f02c4f42bc869a6f0985d A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xba38694cc3f00fb765d71dc5efb20fc5cc41b04ac6e6beffd45bea97cc43180a flow.AccountCreated: 0x66e7f1f426d5da27fa0369615c557149bbc8cabe975a300a46f87c8219416371 flow.AccountKeyAdded: 0x52c38703ba64623b9210ff2b1484464f2c01735bb202db7cc809d71eaccb03d6 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x6f0592f1f3fcba425224850ef7afde7fff44f1603fcd16481c8d56eb88e8f80e A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x9df8b7b9b921c2dbd424a6e010ee68c3ec0ec4d82a7079ac2914e5b58c1fcb43 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x62ab2a65e832cba75d53695f5d53a9965da6325ab985ecfe73d44b1f6bd0d49a]
# 2021/08/30 11:33:36
# 2021/08/30 11:33:36
# 2021/08/30 11:33:36 ---------
# 2021/08/30 11:33:39 network:  testnet
# 2021/08/30 11:33:39 ---------
# 2021/08/30 11:33:39
# 2021/08/30 11:33:39
# 2021/08/30 11:33:39 account:  non-allowance
# {9a0766d93b6608b7    }
# 2021/08/30 11:33:39 getting key:  non-allowance
# 2021/08/30 11:33:39 key:  testnet-non-allowance
# 2021/08/30 11:33:39 getting key:  owner
# 2021/08/30 11:33:39 key:  testnet-owner
# Transaction ID: c2ef2cae534b16246d0c1a39817c7b51355dcce453c880c01f9109eaaec9e2ed
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:33:51 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x5e70df38857ad8b8ccc1dd5216a9bc6490736caa72b46c3bbf3c4988ec38f58c A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xf2ef70f35c2e5fb83b938eebec3618bc32c72e35841d2d2fb86e49e6bffe113d A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x2293b35f88d1ac1158310b7f7e89575711d03e7f60296a1e88881e3d4a9bb3a5 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x56c77e02ebbce977b2200e4fd0a47531d54e94d4b3244b169f4c218c83588482 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa06de67d3617c162aa8e853c9eb1aec147e58d061e85725a4b8575b3cf5626cb flow.AccountCreated: 0x91c66cba3b211f1ca350ad584887ac498386d4c8244358ebe155ce5875fb856a flow.AccountKeyAdded: 0xcf245a96f3b0b1f1d61e76f426088491a956d4ea31a572eae7c5ac2a6dd08769 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x3f3eb86c630eee841587cec22f5418030b47f515749c5bd3b7494416621b3903 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa0f25adcda1878461ed4f41b2042f1c71476474874120b313b758c06eee021eb A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x960af9253b327609aefc98567fa939de30ac884ce6ba5f975be3485a6d2379cf]
# 2021/08/30 11:33:51
# 2021/08/30 11:33:51
# 2021/08/30 11:33:51 ---------
# 2021/08/30 11:33:54 network:  testnet
# 2021/08/30 11:33:54 ---------
# 2021/08/30 11:33:54
# 2021/08/30 11:33:54
# 2021/08/30 11:33:54 account:  non-blocklister
# {9a0766d93b6608b7    }
# 2021/08/30 11:33:54 getting key:  non-blocklister
# 2021/08/30 11:33:54 key:  testnet-non-blocklister
# 2021/08/30 11:33:54 getting key:  owner
# 2021/08/30 11:33:54 key:  testnet-owner
# Transaction ID: 4245d57caca5d887c0b40849d9bd20587b6c6375f7eccfebef53fc2db88eb660
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:34:06 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x189d902c60f4ade496dcced7f98905a933547c6612039001fc7b23f334026cfc A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xd11678a4583f9d49a0df4e88e2aa7f227e46c445e52465052d36f8150b747750 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x88fc68023ad6f846d119a62a5ba216a50555a7eaccaa3497593eb8de3e8a3295 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x7ff9a9554343f5ba8ae43a5618a7296b97a665ae83b490a7e2e6809009759f86 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x7d8987ff235973f30a86ccb0429fbb6e42f7d2ee05205baeb5361b22c97b4dc4 flow.AccountCreated: 0x938f1683ca505a0bd638ba2753b2c2b33910a56190486e9f9bdb977ecd5550c8 flow.AccountKeyAdded: 0xbffe060dcff59018f1edaf99517e7b31200b8da29c8c9e7993fa830c13a14cb2 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x33f9b3e660fad430076c0da55c3f5166d8a6fb539778a8a843ababb601e7c58b A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xcca71c66991479f5125433422d20fdab3769e0d0d559f70f68776c17c4a9ed66 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x008d9c12f51b256f8a73fd38fc78f3b3ab170ed1a8045c9ebc6d91f7b446cb59]
# 2021/08/30 11:34:06
# 2021/08/30 11:34:06
# 2021/08/30 11:34:06 ---------
# 2021/08/30 11:34:08 network:  testnet
# 2021/08/30 11:34:08 ---------
# 2021/08/30 11:34:08
# 2021/08/30 11:34:08
# 2021/08/30 11:34:08 account:  non-minter
# {9a0766d93b6608b7    }
# 2021/08/30 11:34:08 getting key:  non-minter
# 2021/08/30 11:34:08 key:  testnet-non-minter
# 2021/08/30 11:34:08 getting key:  owner
# 2021/08/30 11:34:08 key:  testnet-owner
# Transaction ID: 3e1b7e21cb5b8c3e1ab8ecb0757896ea7a83826773a81ef0a98648d21780ac0d
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:34:20 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x6203fef69434121616333b50511f46e634e1640b66071d3acfa1e5335d6fd4cc A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xe61f763eccfedeb549045e1d98e318436ade754771f4e4c3b1cd9766ef42c151 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xcd0955060390444f204b9ad5f3c2a2f66e3a4db1df3ee750fafd6c14b0bba885 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xdeedbba7b35c44d677c17f50e9fea03ebc10ac661a8c2d60cca4176b8a5ff2d8 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x6a05077a46814cd6218e0fe6299caba27e3d3c7feb53b0a3a7b6cab281455091 flow.AccountCreated: 0xa1090eb8e1ac0f0939d70a25a6c73cb6ee63498a9a1f1afa0e412859b941c48b flow.AccountKeyAdded: 0x343380a608fc2f7112b5e2462cd54ae0159267badca3aa39a000b75eb7ca8790 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x3b51b9400556b5352d0fdbd059bf45b2fead3dd66040ee8f9d95a5ca911d9ca6 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x3762199ac547457cbb59c0ff97ec5e21345bf160c6e3d1746dfaaaeea5bbf8fc A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xa1e207dfd0248936086812695016209e7ca4f640dfbb38b5e027176c522c2640]
# 2021/08/30 11:34:20
# 2021/08/30 11:34:20
# 2021/08/30 11:34:20 ---------
# 2021/08/30 11:34:22 network:  testnet
# 2021/08/30 11:34:22 ---------
# 2021/08/30 11:34:22
# 2021/08/30 11:34:22
# 2021/08/30 11:34:22 account:  non-multisig-account
# {9a0766d93b6608b7    }
# 2021/08/30 11:34:22 getting key:  non-multisig-account
# 2021/08/30 11:34:22 key:  testnet-non-multisig-account
# 2021/08/30 11:34:22 getting key:  owner
# 2021/08/30 11:34:22 key:  testnet-owner
# Transaction ID: e624b7b4b94b9cb484333ba0b4ad680d61eaec4ebb54571121de1b9932f89514
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:34:37 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x26eb1d1927912f1254cb210bbbba5e974278febf5dc03f48d0b3f4b3280583ab A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x8db0691513692e94584a55a454b7db6110ad75fadcbca4bfd923d15b1783cdc1 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x78f2bd7a3e77ebd506b2eeefed60411d4a07ed58d18c889abe1efb56796afa60 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x3d14932528342b212da4e5790a6b42401c9789f3203153f6ecb91f116645b2b5 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xe1ba48037b5d7617ee93296d62d066f31a5466be0ebe8f4bac68fc249e3656d0 flow.AccountCreated: 0x4143a622ee4ddb070bf5318f36ca4b7e1a44fd7c747334c28041642c59c3432b flow.AccountKeyAdded: 0xaaa3b20c0459f9f911c9b90cc62f1634b4b41832158f6f8aeb830f05d644dbb5 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x63392d20d5f166dbab9ecd340c671fb2ddc47d59101d77f1090fa0b2b638dafc A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x028fa4b26e76603974ec4edb1b158116fc33595878ce9fee801b75587fa23e55 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x613dcbb28a7e43ef82aab612181d03b6fe218ec13cc8390a7cd4fda15379344f]
# 2021/08/30 11:34:37
# 2021/08/30 11:34:37
# 2021/08/30 11:34:37 ---------
# 2021/08/30 11:34:39 network:  testnet
# 2021/08/30 11:34:39 ---------
# 2021/08/30 11:34:39
# 2021/08/30 11:34:39
# 2021/08/30 11:34:39 account:  non-pauser
# {9a0766d93b6608b7    }
# 2021/08/30 11:34:39 getting key:  non-pauser
# 2021/08/30 11:34:39 key:  testnet-non-pauser
# 2021/08/30 11:34:39 getting key:  owner
# 2021/08/30 11:34:39 key:  testnet-owner
# Transaction ID: 065ddc4aa6067b16940d283c6e3a02e6495567f9bdfd084ab6c5775018582eb8
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:34:54 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x85d003909d2b3902c8c08a49ee9bcf9f3518285841bec78c1ab2e0007ab4a394 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xe32dd8a6a7890a0f5336c09c9a58e216f19e9cd0f256109e1adf4744b99ddce2 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x2838e4c00c151407c4fee853ce7d0eadcb06823a9340f2149cb799a3ff30ab3c A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x2eee110ee663e726a7d90071efc46745255b73be8e66c9408102142fab3cd6d2 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa741af1e379c9115fa8fd1006bc8b8ae72f878f61a0061107628f480bc9a9007 flow.AccountCreated: 0xbbff4e484d26a079e4a3d41ec30e56387158ea4a86a0df1898c50d770c075ef8 flow.AccountKeyAdded: 0x128532fba60d8ba3146710f8a22689308c05884251ae5521f2543686a8a1ea8b A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xeafa73b1667355b520312c30d9ea41569b6febeeb29d000d89ab253c079fd669 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xc4571af04b431c0ef46be6d1ffc0c3d5d9839273e92d3c2748033d02022234bb A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x59fbfc56b4059c1fff274f80fd8eab47ddb9cccf61cb303151f3245954eeb71b]
# 2021/08/30 11:34:54
# 2021/08/30 11:34:54
# 2021/08/30 11:34:54 ---------
# 2021/08/30 11:34:56 network:  testnet
# 2021/08/30 11:34:56 ---------
# 2021/08/30 11:34:56
# 2021/08/30 11:34:56
# 2021/08/30 11:34:56 account:  non-vaulted-account
# {9a0766d93b6608b7    }
# 2021/08/30 11:34:56 getting key:  non-vaulted-account
# 2021/08/30 11:34:56 key:  testnet-non-vaulted-account
# 2021/08/30 11:34:56 getting key:  owner
# 2021/08/30 11:34:56 key:  testnet-owner
# Transaction ID: e3aff95710b160fca32c55b46c87c185310136a1c576457c1fc0300b0d241901
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:35:08 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x0cd7bac252d27931d54b7df6f34abdbc52552351b099162bacf025df31ede1ec A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x9cc40c3d809d6466c7c82e39a22c171f1188e6913aff8b6716b26618cd1330ce A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xfb13413eec7a76a9b0e48e7be68d629c0c576e11811936bca4f17260738aeb3d A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x4d2431d2cb20ce0799db552e8550799cc168a9207eb4a29bb0cac6fd5bb9f83a A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x0f6a3fbb4aaea3f9b84a553d5c206d76aba48971be103e3218c215960f178ca6 flow.AccountCreated: 0x4b6a7ead2292710722232775d572560cf85b332009a8ceee1dcfba9ff2b3ea38 flow.AccountKeyAdded: 0xe15fa48ff9d9b23aa23bda01fe5a9400bb03813b04b3b7add1c7cf37f0942262 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x5d4d9256fea053c40c6e02e9aa5a1c54f59c4f73e20ff8072a20a2909034a249 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x6f70ab1a44fa7c2dfc1aca36aa721ed6b634cb32cc125697592836726f1782cf A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xcc244fcdd51d16f81c3f19b33ddef2c4c9dba15e8d47c1a8792c2327a64e5e3b]
# 2021/08/30 11:35:08
# 2021/08/30 11:35:08
# 2021/08/30 11:35:08 ---------
# 2021/08/30 11:35:10 network:  testnet
# 2021/08/30 11:35:10 ---------
# 2021/08/30 11:35:10
# 2021/08/30 11:35:10
# 2021/08/30 11:35:10 account:  pauser
# {9a0766d93b6608b7    }
# 2021/08/30 11:35:10 getting key:  pauser
# 2021/08/30 11:35:10 key:  testnet-pauser
# 2021/08/30 11:35:10 getting key:  owner
# 2021/08/30 11:35:10 key:  testnet-owner
# Transaction ID: 279593686d61206ead0c9a98b7a99fddc1d32abbdcadc3126115c5913ac2d010
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:35:24 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x2cdf2810f21d4028c3230ff3033c0403940e90d939fa925eea151a14deea85d4 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xecf9de96029a7282d38b3306e9a75205a4024a687d5c6413ea35812bd5cd9971 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x116b717eb0692c8c25be7fcb0b5385b74f9f7280cbef868d069bce8d8a547521 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x9f1d9e227eaea07925d6477dc48d7ee8798baeeb60864af1418578f4d3161e1d A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa8cf4e9f19dbfd6c78b4a4f4f43cbf51c53731e57a792f05093c484c70043b42 flow.AccountCreated: 0xcb05d1152f1e635f7f00fa40606467c0f7a279b2defc82c4f0bbea624486aea2 flow.AccountKeyAdded: 0x5a0b0d5d90672c9eab2b1c8267aa705e30ab66e4b786c5746cba03bde3f062a8 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xc20f86b20e49eaa911d3847f46890986be8e78156b1058480484c70c1c560820 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x6fd6a55ebafeb71dab1bc450ad2debf858f32a68d7a3b60b1b5cdd5c84c8ab03 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xe725fde00a37ba5eccea2ee18f6cff1f8309494e856a8850d7c1573003a1c7f5]
# 2021/08/30 11:35:24
# 2021/08/30 11:35:24
# 2021/08/30 11:35:24 ---------
# 2021/08/30 11:35:26 network:  testnet
# 2021/08/30 11:35:26 ---------
# 2021/08/30 11:35:26
# 2021/08/30 11:35:26
# 2021/08/30 11:35:26 account:  vaulted-account
# {9a0766d93b6608b7    }
# 2021/08/30 11:35:26 getting key:  vaulted-account
# 2021/08/30 11:35:26 key:  testnet-vaulted-account
# 2021/08/30 11:35:26 getting key:  owner
# 2021/08/30 11:35:26 key:  testnet-owner
# Transaction ID: d87ea7079cddc6cc9b8503711fcedeca130d1cc28b5410d9988945774bfe54c8
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:35:41 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xa2574029364a65de95be6d8692c681e6c4674de7f2ed1d7abd59af77cec5cd66 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xfcf17e08685d4dd1c0850e36435ab9714e3ecfde3de89a7b08ac0fdfcbdf9917 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x02e977b4893249a8ff5752562d3bd480b0c25526eb46a26e5a49beb2526f91a7 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x868b5ab86eb852f59701f2dc48d57de2961cd40a3c60ee9a6efa9d7239a2c94e A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa2668b4d98bbc703d2a2d0ccb59b63400ec77d5790bb93e2f30d737f3ab8e4d4 flow.AccountCreated: 0x01b076d161c11a10038d5a60446c767648fe06187bfd707833d94083a20b6fa6 flow.AccountKeyAdded: 0xe295baef0c83b50c0c764e9626de792d99765c5314b89bf6822098a67b843936 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xf4ff7f41a8031158ece608a56d9952e73557823e33d853d355e64bf652e3e88c A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x8090dcfebcd8bc624311d3c14263be7c2a61a81603f1eededadd32fdbfa92ba4 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x58cad207ec334ec6ae912b6433572eb5d8840acad887b6b9be90b585189336a3]
# 2021/08/30 11:35:41
# 2021/08/30 11:35:41
# 2021/08/30 11:35:41 ---------
# 2021/08/30 11:35:44 network:  testnet
# 2021/08/30 11:35:44 ---------
# 2021/08/30 11:35:44
# 2021/08/30 11:35:44
# 2021/08/30 11:35:44 account:  w-1000
# {9a0766d93b6608b7    }
# 2021/08/30 11:35:44 getting key:  w-1000
# 2021/08/30 11:35:44 key:  testnet-w-1000
# 2021/08/30 11:35:44 getting key:  owner
# 2021/08/30 11:35:44 key:  testnet-owner
# Transaction ID: 088413afd81e3427fd8e05105ba176f7c12089cfcaa9021f6e4941bb5a507c78
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:35:58 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x860bd4d20fbe3728016f32bf4ac6ba4133f5b7b8452350a40e87915c9c304416 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x5a27644c3a50bd0c05ac137eb1b13f2bcaba45e2f03a983f2cabd8f922ee5155 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x704fd576a979938d4c7ca2fbf0ae33724ea044770bdad69f1bfa5d9b00c015c5 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xbd88038d9e5f748ecdea1456b9469333a3b44fc4343bbd01db506b3bcaf4661c A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x384ccfe1343159a99ad274e57e0b34495972ce249e8b53ff34c84f8d8008fd6e flow.AccountCreated: 0x04a846da0acbc472a862fd26247d1686d89129c38d2cc45fe71a4753f07d5f69 flow.AccountKeyAdded: 0x8cc2cb11749fbd774967011a91363d0fb3864c3e1c6a1fc95f9cddb6a89c7e33 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x2176c86576d692a32ddf1c707e90ba839215f0bc2dfb0af170dcbc4d191689d6 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xff8d538327c9e6eecbbc0802e723f8daab4ed99839c7347dd2741b35efab7f63 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xaba574de4b9dede2cd05f3777f15305309449fe999e59119cde72d2c7a9bfc3c]
# 2021/08/30 11:35:58
# 2021/08/30 11:35:58
# 2021/08/30 11:35:58 ---------
# 2021/08/30 11:36:00 network:  testnet
# 2021/08/30 11:36:00 ---------
# 2021/08/30 11:36:00
# 2021/08/30 11:36:00
# 2021/08/30 11:36:00 account:  w-250-1
# {9a0766d93b6608b7    }
# 2021/08/30 11:36:00 getting key:  w-250-1
# 2021/08/30 11:36:00 key:  testnet-w-250-1
# 2021/08/30 11:36:00 getting key:  owner
# 2021/08/30 11:36:00 key:  testnet-owner
# Transaction ID: 1cd35d9dc8ac2016f7f6b702f8f3d3defe9cb55598437b28f986e9da826486c2
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:36:13 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xac402ff2981b4d3b6abab1f68e44f4b6f4ecc240ef5bae3b0c4c1d9ec6db4540 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x8341c8d4edb36ce225e5204008d508a70bf0d07513b1af3dcd896fc6968d4d4c A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xdb11933a365c0155a25135fd0fe76b325e0d1487fa10b59eb420ffc6c4db6b19 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x5ace60cb2f1ebefd0804f155d71d180b6bcf14a10bddecaa937937e0b61a1b21 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xe25d1ec9a240278b03389f6a3518cc86a583cd7f0d16f0733a35bb6bfb53d5ed flow.AccountCreated: 0xc309a2354c3177eaef494c4f39d6677e68d05ecdc18a6455e8f5820eeafb70c5 flow.AccountKeyAdded: 0x6ad844e991aaf1c53619752b753fe3d81480d046dd0538ae22f132cb2d015138 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x4cdd9d81bb1bc53b7aa06b9f628691766785b43fa39c9c23d1776aea4c38a53b A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x6e6f0540b678e24d4c0c54c102928a1faceab6b4ed8eb62f67ff34b9225642b6 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xfc5658c9a4f9eb00658f5d55bf3bc7050682f6f2d89ff35a3495a0eabd8a8095]
# 2021/08/30 11:36:13
# 2021/08/30 11:36:13
# 2021/08/30 11:36:13 ---------
# 2021/08/30 11:36:15 network:  testnet
# 2021/08/30 11:36:15 ---------
# 2021/08/30 11:36:15
# 2021/08/30 11:36:15
# 2021/08/30 11:36:15 account:  w-250-2
# {9a0766d93b6608b7    }
# 2021/08/30 11:36:15 getting key:  w-250-2
# 2021/08/30 11:36:15 key:  testnet-w-250-2
# 2021/08/30 11:36:15 getting key:  owner
# 2021/08/30 11:36:15 key:  testnet-owner
# Transaction ID: 1dbe54f4ff278733ad6b61db8f1dada168424eb23800b7ba8d3a23bcdb8c0f84
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:36:28 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x65f34f3ca57c6919ad666b89277da7ff7f94cf190d82f551862549d35c06f21b A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x0e3cb8bd2fb3c3d528c62288248b8b15cb00e3ca7ccab6032ce35c9ece95d683 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x380a0c3812ea67d9579a5cae26d9ca6d52e70128882919f7f4a7171a80b5e9bd A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x25356415a37de6a47d224c9e0381eace2ac1c4653766cc585506b05f663e70a4 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xb8945c47a07692911bece2cd32a94ebea7f5031b66debd517faf29b3363bc290 flow.AccountCreated: 0x04f84d216c63cf55cf6b9ce5b4634729afa9443cf7a87617e3936917fdb49e3e flow.AccountKeyAdded: 0x8b03b13ee6dfc89152b91d01fb6dbcff4ecc627cc8427fd9705e86c009c6c835 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x1927eff5940b4b3b97c0c145bb35beb8936f7f81957b399606079824fa127abd A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xdd45728a3027d6232d080c0835b06e098954fde58823aea3862556f34e710364 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x3adcccbd446548cfe2efb87cd424e3325a758d4c232eb11f7092f89fd6332de0]
# 2021/08/30 11:36:28
# 2021/08/30 11:36:28
# 2021/08/30 11:36:28 ---------
# 2021/08/30 11:36:30 network:  testnet
# 2021/08/30 11:36:30 ---------
# 2021/08/30 11:36:30
# 2021/08/30 11:36:30
# 2021/08/30 11:36:30 account:  w-500-1
# {9a0766d93b6608b7    }
# 2021/08/30 11:36:30 getting key:  w-500-1
# 2021/08/30 11:36:30 key:  testnet-w-500-1
# 2021/08/30 11:36:30 getting key:  owner
# 2021/08/30 11:36:30 key:  testnet-owner
# Transaction ID: ca583ddf4c7cef5fadae13757ccfd1a9325edfee9b3e2f7d981741ad0d8f77f4
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:36:45 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x671947fbd5d7cfe964e933d0c60689192b0791bf5ece13e8ace8550e03841e8d A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xd06958733463dc0b47749ae92d4b4e88be5059972529fc21ce8ff400a748817e A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xb89a80e0d0f9c14e9d5d688fd62e81acc113333278c18ea8dff2b0073b614248 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xda96855578956645eb56c2d31a37f58c41b611fe179072a381592dc8c8e4ecc3 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa5f08074b7391fe85fefdaf5827903af400fb6c04f5bb9c324aa2d1203f6182b flow.AccountCreated: 0x1eb38d71151c1a560dbf2abea73abf282afc5c0d1d3f776882ce6755606af31a flow.AccountKeyAdded: 0x4b5dcf12310bf8221667e1f353b4d8abe1dc94b77206c6c2b101391f1e313055 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xa759376b57135a0b67cf8e38776b505d42fab531d5a4de350116559d93df4c23 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x7a673255996b7d4b47a56c227c499ce39679c8a047ebd66b3360ba908d21f12d A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xb4165dca6086afa7388fdd5f345a07d1666ea8ca844f5b30dbb0034fe9324a41]
# 2021/08/30 11:36:45
# 2021/08/30 11:36:45
# 2021/08/30 11:36:45 ---------
# 2021/08/30 11:36:48 network:  testnet
# 2021/08/30 11:36:48 ---------
# 2021/08/30 11:36:48
# 2021/08/30 11:36:48
# 2021/08/30 11:36:48 account:  w-500-2
# {9a0766d93b6608b7    }
# 2021/08/30 11:36:48 getting key:  w-500-2
# 2021/08/30 11:36:48 key:  testnet-w-500-2
# 2021/08/30 11:36:48 getting key:  owner
# 2021/08/30 11:36:48 key:  testnet-owner
# Transaction ID: 070da116b33decd50adf616c994172d5ac236202732247c4b31aa797aecee774
# 👌 Transaction ../../transactions/flowTokens/create_account_testnet.cdc successfully applied
# 
# 2021/08/30 11:37:01 [A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0xb6676438498b46f506e1896f0ab8387db4f9ea1dce1b394ee3abdef8368a6c31 A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x50d49b6ae4d1b73dec742e232810ec0ccbdcb454e6da822f0abaec38e80da8e3 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x6cc416d9be6ecfff878930bc968772264c55bb9449b36282ce0b4cca08b0d8e6 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0xee63182cb7a61d65330c4dde2fed881217f7644e2ef96a14a5cafc23cd99014c A.7e60df042a9c0868.FlowToken.TokensDeposited: 0x228e1809c3a95877169d41e02d5d9ddefab7a05213667f4032ad34bf2b720a9e flow.AccountCreated: 0x261f33cc7b9413d817dbc783a7925c3d855660ce78bf35a7d225be3b688140ec flow.AccountKeyAdded: 0x80ef278d950cb44a8eaaa623c419881a798cbe2620eb97b17aa6cc00b159122a A.7e60df042a9c0868.FlowToken.TokensWithdrawn: 0x04b2114036a48b5fac8f4b015aba058ed7da980aa1055603189161d727a99709 A.7e60df042a9c0868.FlowToken.TokensDeposited: 0xa25edce16a09c8b2f6e3e4050f868099f39852b0e78ecc9a8e142c1a567f3660 A.912d5440f7e3769e.FlowFees.TokensDeposited: 0x5e8ee10db597a48d169a93259174f3b44f48a1901b8b28cab023d21f9d798001]
# 2021/08/30 11:37:01
# 2021/08/30 11:37:01
# 2021/08/30 11:37:01 ---------
