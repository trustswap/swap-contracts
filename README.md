# SwapToken

SwapToken is ERC-20 token used to schedule automatic payout transactions on Ethereum blockchain.

  - Name: SwapToken
  - Symbol: SWAP
  - Decimals: 18

### Prerequisites
Make sure you are equipped with the following:
  - node.js and npm
  - ganache-cli or the Ganache desktop app

### Install truffle and truffle-flattener
```sh
$ npm install -g truffle
$ truffle --version
$ npm install -g truffle-flattener
```

### OpenZeppelin SDK installation

```sh
$ npm install -g @openzeppelin/cli
```
To check if you have already installed OpenZeppelin SDK or to make sure that the installation process was successful you can verify the version of your software:

```sh
$ oz --version
```

### Download source code
```sh
$ git clone https://kr_ronak@bitbucket.org/krdevs/swaptoken_upgradable.git
$ cd swaptoken_upgradable
$ npm install
```

### Start Ganache ( In different terminal )
```sh
$ ganache-cli
```

### Compile & Deploy Contracts using Truffle
```sh
$ oz init
$ truffle compile
$ truffle migrate --network <development/ropsten/mainnet/mainnet_fork>
```

### Compile & Deploy using OpenZeppelin
```sh
$ oz push --deploy-dependencies
$ oz create
$ oz compile
$ oz deploy
```

### Upgrade contract on Mainnet fork using OpenZeppelin
```sh
$ ganache-cli --fork https://mainnet.infura.io/v3/<INFURA_KEY>
$ cp .openzeppelin/mainnet.json .openzeppelin/mainnet.json.bkp
$ oz push --network mainnet_fork
$ oz upgrade --network mainnet_fork
```

### Interact with deployed contract using OpenZeppelin
For non-payable ( view only ) functions:
```sh
$ oz call
```
For payable functions:
```sh
$ oz send-tx
```

### Source Verification on Etherscan
Get deployed contract address (implementation address) from .openzeppelin/<dev-XXX/ropsten/mainnet>.json at bottom
```sh
"proxies": {
    "swaptoken/SwapToken": [
      {
        "address": "0x31b49e94b0f5337D16b1F758991006838767294b",
        "version": "1.0.0",
        "implementation": "0xb97D7118209eb9e34ae355bdEDa8F53ED118F199",
        "admin": "0x2A02a607C399204680537F59aD9a8701B640315d",
        "kind": "Upgradeable"
      }
    ]
  },
```
```sh
$ truffle-flattener contracts/SwapToken.sol > FlattenedSwapToken.sol
```
Select compiler version as 0.6.2 and copy contents of FlattenedSwapToken.sol

