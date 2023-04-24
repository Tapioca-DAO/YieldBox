if [[ "$1" ]]
then
    RULE="--rule $1"
fi

if [[ "$2" ]]
then
    MSG="- $2"
fi

certoraRun  certora/harness/YieldBoxHarness.sol \
    certora/munged/ERC1155TokenReceiver.sol \
    \
    certora/helpers/DummyERC20A.sol \
    certora/helpers/DummyERC20B.sol \
    certora/helpers/DummyERC721A.sol \
    certora/helpers/DummyERC721B.sol \
    certora/helpers/DummyWeth.sol \
    \
    certora/munged/strategies/SimpleMintStrategy.sol \
    \
    --verify YieldBoxHarness:certora/spec/sanity.spec \
    --link YieldBoxHarness:wrappedNative=DummyWeth \
    --solc solc8.9 \
    --loop_iter 2 \
    --staging master \
    --optimistic_loop \
    --rule_sanity \
    --send_only \
    $RULE \
    --msg "YieldBox: $RULE $MSG" 

    # certora/munged/strategies/SimpleMintStrategyAdditional.sol \