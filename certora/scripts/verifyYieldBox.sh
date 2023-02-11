cd certora
touch applyHarness.patch
make munged
cd ..
echo "key length" ${#CERTORAKEY}

certoraRun  certora/harness/YieldBoxHarness.sol \
    certora/helpers/DummyWeth.sol \
    certora/helpers/DummyERC20A.sol certora/helpers/DummyERC20B.sol \
    certora/helpers/DummyERC721A.sol certora/helpers/DummyERC721B.sol \
    certora/helpers/DummyERC1155A.sol certora/helpers/DummyERC1155B.sol \
    certora/helpers/mainStr/DummyERC20Str.sol certora/helpers/mainStr/DummyERC721Str.sol certora/helpers/mainStr/DummyERC1155Str.sol \
    certora/helpers/additionalStr/DummyERC20AddStr.sol certora/helpers/additionalStr/DummyERC721AddStr.sol certora/helpers/additionalStr/DummyERC1155AddStr.sol \
    certora/munged/YieldBoxURIBuilder.sol certora/munged/ERC1155TokenReceiver.sol \
    certora/munged/mocks/MasterContractMock.sol \
    certora/munged/strategies/SimpleMintStrategy.sol certora/munged/strategies/SimpleMintStrategyAdditional.sol \
    certora/helpers/Receiver.sol \
    certora/munged/NativeTokenFactory.sol \
    --verify YieldBoxHarness:certora/spec/yieldBox.spec \
    --link YieldBoxHarness:wrappedNative=DummyWeth \
    --solc solc8.9 \
    --cloud \
    --optimistic_loop \
    --rule mapArrayCorrealtion assetIdtoAssetLength erc20HasTokenIdZero balanceOfAddressZeroERC20 balanceOfAddressZeroYieldBox tokenTypeValidity withdrawIntegrity yielBoxETHAlwaysZero strategyCorrelatesAsset tokenInterfaceConfusion depositETHCorrectness \
    --send_only \
    --settings -t=2000,-mediumTimeout=2000,-depth=100 \
    --msg "YieldBox - all"