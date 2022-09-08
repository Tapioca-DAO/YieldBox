certoraRun  certora/harness/YieldBoxHarness.sol \
    certora/helpers/DummyWeth.sol \
    certora/helpers/DummyERC20A.sol certora/helpers/DummyERC20B.sol \
    certora/helpers/DummyERC721A.sol certora/helpers/DummyERC1155A.sol \
    certora/munged/YieldBoxURIBuilder.sol certora/munged/ERC1155TokenReceiver.sol \
    certora/munged/mocks/MasterContractMock.sol \
    certora/munged/strategies/SimpleMintStrategy.sol \
    certora/helpers/Receiver.sol \
    --verify YieldBoxHarness:certora/spec/yieldBox.spec \
    --solc solc8.9 \
    --cloud \
    --optimistic_loop \
    --send_only --rule_sanity basic \
    --rule "$1" \
    --msg "YieldBox - $1"

