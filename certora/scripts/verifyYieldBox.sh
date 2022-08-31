certoraRun  certora/harness/YieldBoxHarness.sol \
    certora/munged/AssetRegister.sol \
    certora/helpers/DummyWeth.sol \
    certora/helpers/DummyERC20A.sol certora/helpers/DummyERC20B.sol \
    certora/helpers/DummyERC721A.sol certora/helpers/DummyERC1155A.sol \
    certora/harness/MasterContractHarness.sol \
    certora/munged/YieldBoxURIBuilder.sol certora/munged/ERC1155TokenReceiver.sol \
    certora/munged/strategies/SimpleMintStrategy.sol certora/munged/AssetRegister.sol \
    --verify YieldBoxHarness:certora/spec/yieldBox.spec \
    --solc solc8.9 \
    --staging \
    --optimistic_loop \
    --send_only \
    --msg "YieldBox - array getters check from harness"

