cd certora
touch applyHarness.patch
make munged
cd ..
echo "key length" ${#CERTORAKEY}


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
    --verify YieldBoxHarness:certora/spec/yieldBox.spec \
    --link YieldBoxHarness:wrappedNative=DummyWeth \
    --solc solc8.9 \
    --loop_iter 2 \
    --optimistic_loop \
    --rule_sanity \
    --rule mapArrayCorrealtion \
    --send_only \
    $RULE \
    --msg "YieldBox check: mapArrayCorrealtion" 