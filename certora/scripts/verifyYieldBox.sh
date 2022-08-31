if [[ "$1" ]]
then
    RULE="--rule $1"
fi

if [[ "$2" ]]
then
    MSG=": $2"
fi

certoraRun  certora/munged/YieldBox.sol \
    certora/munged/AssetRegister.sol \
    certora/helpers/DummyWeth.sol \
    certora/helpers/DummyERC20A.sol certora/helpers/DummyERC20B.sol \
    certora/helpers/DummyERC721A.sol certora/helpers/DummyERC1155A.sol \
    certora/harness/MasterContractHarness.sol \
    certora/munged/YieldBoxURIBuilder.sol certora/munged/ERC1155TokenReceiver.sol \
    certora/munged/strategies/SimpleMintStrategy.sol \
    --verify YieldBox:certora/spec/yieldBox.spec \
    --solc solc8.9 \
    --staging \
    --optimistic_loop \
    --send_only \
    $RULE  \
    --msg "YieldBox -$RULE $MSG" #\

