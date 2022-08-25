certoraRun  certora/munged/YieldBox.sol \
    certora/helpers/DummyWeth.sol \
    certora/helpers/DummyERC20A.sol certora/helpers/DummyERC20B.sol \
    certora/helpers/DummyERC721A.sol certora/helpers/DummyERC1155A.sol \
    certora/harness/MasterContractHarness.sol \
    certora/munged/YieldBoxURIBuilder.sol certora/munged/ERC1155TokenReceiver.sol \
    --verify YieldBox:certora/spec/yieldBox.spec \
    --solc solc8.9 \
    --staging \
    --optimistic_loop \
    --send_only \
    --msg "YieldBox - sanity check, added tokens"

