## Run Private Blockchain with Encifher chainid and PoA consensus 

Note: Custom genesis file can't be used with --dev 

1. Create custom data dir and initialize geth using genesis.json

    `geth --datadir ./blockchainData init ./genesis.json`

2. Start the node using following command
    `geth --datadir ./blockchainData/ --http --http.api debug,personal,eth,net,web3 --http.corsdomain "*" --allow-insecure-unlock --dev --networkid 912009 --dev.period 2 --http.port 8545 --ws`
    
    Starts an execution client with chain id 912009, to check use: 
    
    `curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":67}' 127.0.0.1:8545`
