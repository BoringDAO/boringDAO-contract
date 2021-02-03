# BoringDAO-contracts

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
