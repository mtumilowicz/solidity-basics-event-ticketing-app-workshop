# solidity-basics-event-ticketing-app-workshop

* references
    * https://www.investopedia.com/terms/b/basic-attention-token.asp
    * https://medium.com/@danielyamagata/understand-evm-opcodes-write-better-smart-contracts-e64f017b619
    * https://ethereum.stackexchange.com/questions/117100/why-do-many-solidity-projects-prefer-importing-specific-names-over-whole-modules
    * https://medium.com/@eiki1212/what-is-ethereum-gas-simple-explanation-2f0ae62ed69c

## memory model
1. storage
    * permanent storage space
        * stored on the blockchain
    * where all state variables are stored
    * each contract account has its own storage and can only access their own storage
        * it is not possible to directly access the storage of another account
        * each Ethereum account has its own unique address and associated storage
            * this address is derived from the account's public key
            * as a result, only the account owner has the private key necessary to access or modify the storage
        * think of storage as a private database
    * thinking of the storage as an array will help us understand it better
        * each space in this storage "array" is called a slot and holds `32` bytes of data (`256 bits`)
        * maximum length of this storage "array" is `2²⁵⁶-1`
        * each slot can be occupied by more than one type
            * unless sum of bytes are <= 32
            * so order matters
        * example
            ```
            // SPDX-License-Identifier: MIT
            pragma solidity ^0.8.16;

            contract StorageLayout {
                uint64 public value1 = 1;
                uint64 public value2 = 2;
                uint64 public value3 = 3; // order matters: you will need 3 slots if value3 and value5 are swapped
                uint64 public value4 = 4;
                uint256 public value5 = 5;
            }
            ```
            and we can get storage at specific slot
            ```
            web3.eth.getStorageAt("0x9168fBa74ADA0EB1DA81b8E9AeB88b083b42eBB4", 0)
            // returns: `0x04000000000000000300000000000000020000000000000001`
            // so we have value1, ..., value4 in one slot
            web3.eth.getStorageAt("0x9168fBa74ADA0EB1DA81b8E9AeB88b083b42eBB4", 1)
            // returns: `0x0000000000000000000000000000000000000000000000000000000000000005`
            ```
        * dynamic arrays and structs always occupy a new slot
            * any variables following them will also be initialized to start a new storage slot
    * it is not cheap in terms of gas - so we need to optimize the use of storage
        ```
        contract storageExample {
        uint256 sumOfArray;

            function inefficientSum(uint256 [] memory _array) public {
                    for(uint256 i; i < _array.length; i++) {
                        sumOfArray += _array[i]; // writing directly to storage
                    }
            }

            function efficientSum(uint256 [] memory _array) public {
               uint256 tempVar;

               for(uint256 i; i < _array.length; i++) {
                        tempVar += _array[i]; // using temporary memory variable
                    }
               sumOfArray = tempVar;
            }
        }
        ```
    * Solidity does not have null values
        * not assigning a value to a state variable = assigning its default value based on the type
        * example
            * `address` -> `0x0000000000000000000000000000000000000000`
            * enums -> assigned the first value (index 0)
    * Solidity generates a getter function for public state variables
1. memory
    * works similarly to the memory of a computer, more specifically, the RAM (Random Access Memory)
        * idea of RAM is that information can be read and stored in specific places
        (at a particular memory address) and not just sequentially
    * short-lived
        * reserved for variables that are defined within the scope of a function
        * gets torn down when a function completes its execution
1. stack
    * works on the LIFO (Last-In First-Out) scheme
    * when the bytecode starts executing, the Stack is empty
    * 1,024 levels deep in the EVM
        * if it stores anything more than this, it raises an exception
1. calldata
    * it is a read-only location
        * example
            ```
            contract Storage {

                string[] messages;

                function retrieve(uint index) public view returns (string calldata){
                    return messages[index]; // not compiling
                }
            }
            ```
            * for it to work: need to copy string to the calldata area
                * impossible: calldata is immutable
            * however: if you already have something in calldata though, you can return it
                * calldata can be returned from functions
        * can typically only be used with functions that have external visibility
            * source of these arguments needs to come from message calldata
            * example: passing forward calldata arguments
    * usually the signature of the function to be executed, followed by the ABI encoding of the function arguments
        * can be verified in Remix, under smart contract method you can "Copy calldata to clipboard"
        * example
            * keccak256 online: https://emn178.github.io/online-tools/keccak_256.html
            * function: `function createTicket(string)`
                * `6897082f779ee6aa6c305e01892e057838143a4691bda17d4092e228fc6d147a`
                * selector: `0x6897082f`
            * argument: `c`
                * `0x63`
                * prepending the data length: `0x0163`
                * we need to zero-pad to a 32-byte word
            * calldata: `concat(selector, packedPaddedArgument)`
    * temporary location where function arguments are stored
    * avoids unnecessary copies and ensures that the data is unaltered
    * helps lower gas consumption
        * compiler can skip ABI encoding
            * the data is already formatted correctly according to the ABI
            * for memory: Solidity would need to encode it before returning
    * calldata is allocated by the caller, while memory is allocated by the callee
* assignments will either result in copies being created, or mere references to the same piece of data
    * between storage and memory/calldata - always create a separate copy
    * from memory to memory
        * create a new copy for value types
        * create references for reference types
            * changing one memory variable alters all other memory variables that refer to the same data
    * from storage to storage
        * assign a reference

## smart contract
* program (bytecode) deployed and executed in the Ethereum Virtual Machine (EVM)
* stored on the Ethereum blockchain
* written in a specific programming language
    * example: Solidity, Vyper
* self-executing with the terms of the agreement written directly into code
    * automate processes
        * Token Sales (ICO)
            * can distribute tokens to contributors based on predefined conditions
    * enforce rules
        * Supply Chain Verification
            * can validate products' authenticity based on information stored
            on the blockchain (e.g., origin, certifications), ensuring compliance with predefined standards
    * facilitate transactions
        * Royalty Payments for Creators
            * when revenue is generated from the sale or use of content (e.g., music, art), the smart
            contract automatically distributes the earnings to the creators according to the agreed-upon terms
* ability to create DApps = Decentralized Application
    * example
        * decentralized exchange (DEX): https://uniswap.org
            * allows users to trade cryptocurrencies directly with one another without the need for
            an intermediary or centralized authority
            * instead of relying on order books (as in traditional exchanges) uses liquidity pools and smart
            contracts to facilitate trading
        * NFT game: https://www.cryptokitties.co
    * application that runs on a decentralized network of computers (usually a blockchain)
        * transactions and data stored in a DApp are recorded on a blockchain
        * not controlled by a single entity
    * components:
        * backend
            * smart contract (open sourced)
            * user's cryptocurrency wallet
                * used to manage and control the user's assets within the DApp
        * frontend: GUI user-facing part of the DApp
            * responsible for communicating with the smart contracts on the blockchain
    * often have their own native tokens or cryptocurrencies
        * used to incentivize network participants and can represent various forms of value
        * example: BAT (Basic Attention Token)
            * system for tracking media consumers' time and attention on websites using the Brave web browser
            * its goal is to efficiently distribute advertising money between advertisers, publishers, and
            readers of online marketing content and ads
    * can operate autonomously without the need for intermediaries

## syntax
* example
    ```
    import 'CommonLibrary.sol';

    pragma solidity ^0.8.9;

    contract FirstContract { }
    ```
* `pragma`
    * generally the first line of code within any Solidity file
    * specifies the target compiler version
    * `^`: contract will compile for any version above the version mentioned but less than the next major version
        * example: `0.8.9` will not work with the `0.9.x` compiler version, but lesser than it
    * good practice: compile Solidity code with an exact compiler version rather than using ^
* `import`
    * example
        ```
        import {
            ERC721HolderUpgradeable // way to avoid naming conflicts
        } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
        ```
    * are for your development environment only
        * when you deploy your contracts on the Ethereum blockchain, import statements must be replaced with the actual content of the `.sol` file that you imported
        * Ethereum blockchain takes the flattened files of the smart contract and deploys it
            * content of the imported contract is effectively copied and pasted into the current contract during the compilation process
            * this means that all elements defined in the imported contract become part of the current contract
        * framework, such as Truffle or the Remix IDE, converts all import statements and makes a single flattened contract during deployment
* constructors
    * are optional and the compiler induces a default constructor when none is explicitly defined
    * executed once while deploying the contract
    * can have a payable attribute
        * enable it to accept Ether during deployment and contract instance creation time
* two ways of creating a contract
      * using the new keyword
          * deploys and creates a new contract instance
          * example: `HelloWorld myObj = new HelloWorld();`
      * using the address of the already-deployed contract
          * is used when a contract is already deployed and instantiated
          * example: `HelloWorld myObj = HelloWorld(address);`

# to use
* Dynamic types are not that straightforward, because they can increase and decrease the amount of data they hold dynamically.
    * So they cannot be stored sequentially, as the value types can.
    * For an array, in the slot it is declared only its length is saved, and its elements are stored somewhere else in the storage
    * example
        ```
        uint256[] public values = [1,2,3,4,5,6,7,8];

        bytes32 constant public startingIndexOfValuesArrayElementsInStorage = keccak256(abi.encode(0));

        function getElementIndexInStorage(uint256 _elementIndex) public pure returns(bytes32) {
            return bytes32(uint256(startingIndexOfValuesArrayElementsInStorage) + _elementIndex);
        }
        ```
        * Encoding the index with abi.encode will left-padded with zeros automatically for us.
        * keccak256(0x0000000000000000000000000000000000000000000000000000000000000000)
            * 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
        * If we sum 1 to the index 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
            * web3.eth.getStorageAt("0x080188CFeF3D9A59B80dE6C79F8f35C6843aa41D", "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564")
            0x0000000000000000000000000000000000000000000000000000000000000002
    * These indices are huge and look random since they are calculated withkeccak256 , which will return a 256 bit number, represented as hexadecimal, and we use that hash as the index of the elements of our array.
        * Remember that the storage capacity is 2²⁵⁶-1 elements, so we are good and in range using keccak256 hash as slot index.
        * This makes the probability of 2 or more different state variables sharing the same slot in storage low.
        * Since array elements are stored sequentially from the hash, the same space layout applies to them.
            * If our array was uint8[], then many elements of the array would fit in a single slot until 32 bytes are occupied.