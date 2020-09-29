# boring-contracts

## How to deploy

1. Create a secret.json file in the root directory with the following content
```json
{
    "projectId": "infura projectId",
    "mnemonic": "Mnemonic"

}
```
The first account corresponding to the mnemonic phrase should have testnet eth

2. Run in node environment
```bash
    npm install
    npx truffle compile 
    npx truffle deploy --network kovan 
```

## Contract Info

## Interaction

### client

1. Call the approveMint method in the BoringDAO contract to vote new bBTC
```javascript
function approveMint(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        string memory _assetAddress 
)
``` 
2. Monitor the BurnToken event of the BToken contract

```javascript
event BurnBToken(
        address indexed account,
        uint256 amount,
        address proposer,
        string assetAddress
    );
``` 
