# solidity-basics-event-ticketing-app-workshop

* references
    * https://www.investopedia.com/terms/b/basic-attention-token.asp
    * https://ethereum.stackexchange.com/questions/872/what-is-the-cost-to-store-1kb-10kb-100kb-worth-of-data-into-the-ethereum-block
    * https://medium.com/@danielyamagata/understand-evm-opcodes-write-better-smart-contracts-e64f017b619

# introduction
## EVM = Ethereum Virtual Machine
* refresh: virtual machine
    * is a type of simulation of a CPU
    * has predefined operations, but such operations must be understood by the virtual machine and not by the CPU
    * is a program capable of interpreting a specific language
        * transforming (indirectly) this language into machine language
        * executing what needs to be executed on the CPU.
    * language that the virtual machine understands is called bytecode
        * each virtual machine has its own bytecode with its own definitions
        * bytecode is a series of instructions that the EVM will interpret and execute
        * when we write a smart contract in Solidity or Vyper, the result must be transformed (compiled) to bytecode
        * EVM bytecode is not machine language
            * although it looks like a set of bits, it is only a representation
* Ethereum is like a single-threaded computer
    * it can process one transaction at a time
    * Sharding of blockchain would improve it and make it like a multithreaded computer
* virtual, isolated environment where code (smart contracts) can be executed
    * running on the EVM is not directly executed by any single computer, but by all nodes in the Ethereum network
    * you can think of JVM(Java Virtual Machine) as the same mechanism
* is Turing complete
    * contracts contain very little code and their methods require very few instructions to execute
        * usually less than one thousand
        * regular computers execute several billion instructions per second
    * to prevent infinite loops and resource exhaustion, the EVM requires users to pay for computation and storage
        * Ethereum Virtual Machine is seen only as quasi-Turing complete
        * payment is made in the form of "gas"
            * a unit of measurement for the amount of computational work required to execute operations
        * since the London hard fork, each block has a target size of 15 million units of gas
            * the actual size of a block will vary depending on network demand
                * maximum size of the block gas limit is 30 million gas
                    * means that a block can only contain transactions which cost 30m gas to execute
        * example
            * 3m gas is at maximum 1.5 million instructions (in a very theoretical, unrealistic scenario)
                * example
                    * MSTORE (Memory Store): around 3 gas
                    * SSTORE (Storage Operation):
                        * writing to a new storage slot: Around 20,000 gas (for a 256 bit word)
                            * a kilobyte is thus 640k gas
                                * so if gas ~ 10 gwei
                                * 1KB costs 0.0064 ETH
                                * 1GB costs 6400 eth (for eth 1.5k USD, ~ 12,000,000 USD)
                            * so a block can only contain instructions that write to storage about 150 times
                        * updating an existing storage slot: Around 5,000 gas
                    * SLOAD (Storage Load): around 200 gas
* is deterministic
    * running the same code with the same inputs will produce the same results every time
* is a stack-based machine
* operates using a set of instructions called "opcodes"
    * opcodes are predefined instructions that the EVM interprets
    * some operators have operands, but not all
        * operator that have operand: PUSH
            * push to the stack
        * operator that does not have: ADD
            * takes from the stack, add and push result
    * example
        ```
        // Solidity code
        function addIntsInMemory(uint256 a, uint256 b) public pure returns (uint256) {
            uint256 result = a + b;
            return result;
        }
        ```
        is compiled into operands and operators (opcodes)
        ```
        PUSH1 0x20      // Load the memory slot size (32 bytes)
        MLOAD           // Load 'a' from memory
        PUSH1 0x40      // Load the memory slot size (32 bytes)
        ADD             // Add 'a' and 'b'
        MSTORE          // Store the result back in memory
        ```
    * then it is interpreted to bytecode
* bytecode is a set of bytes that must be executed in order, from left to right
    * each byte can be
        * an operator (represented by a single byte)
        * a complete operand
        * part of an operand (operands can have more than just 1 byte)
            * example: `PUSH20` - used to push a 20-byte (160-bit) value onto the stack
    * example
        * `ADD` opcode is represented as `0x01`
        * `PUSH1` opcode is represented as `60` and expects a 1-byte operand
        * bytecode to analyse: `0x6001600201` -> `60 01 60 02 01`
        * byte `60` is the `PUSH1` opcode
            * adds a byte to the Stack
            * The `PUSH1` opcode is an operator that expects a 1-byte operand
            * Then the complete statement is `60 01`
        * `60 02` // similar
        * final result: number 3 on the Stack
        * digression
            * byte 01 was used both as an operand and operator
            * it’s easy to figure out what it represents in the context of how it was used
    * you cannot generate the exact original Solidity source code from the EVM bytecode
        * process of compiling involves
            * optimizations
            * transformations
            * and potentially even loss of information
                * example
                    * during complication the function names and their input parameters are hashed to generate the function selectors
                    * to compute function selector
                        1. concatenate the function name and parameter types without spaces or commas: `myFunction(uint256,address)``
                        1. calculate the keccak-256 (sha3) hash of the concatenated string
                        1. take the first 4 bytes of the hash
* can be described as a global decentralized state machine
    * more than a distributed ledger
        * analogy of a 'distributed ledger' is often used to describe blockchains like Bitcoin
            * ledger maintains a record of activity which must adhere to a set of rules that govern what someone can and cannot do to modify the ledger
                * example: Bitcoin address cannot spend more Bitcoin than it has previously received
                * Ethereum has its own native cryptocurrency (Ether) that follows almost exactly the same intuitive rules
        * it enables a much more powerful function: smart contracts
    * state = the current state of all accounts and smart contracts on the blockchain
        * includes things like account balances, contract storage, and contract code
    * each transaction on a blockchain is a transition of state
    * EVM is the engine that processes transactions and executes the corresponding smart contract code
        * leads to state changes
        * at any given block in the chain, Ethereum has one and only one 'canonical' state
            * EVM is what defines the rules for computing a new valid state from block to block
* memory model maintains four locations to access and/or store information
    1. storage
        * permanent storage space
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
        * not assigning a value to a state variable = assigning its default value based on the type
            * example
                * `address` -> `0x0000000000000000000000000000000000000000`
                * enums -> assigned the first value (index 0)
    1. memory
        * works similarly to the memory of a computer, more specifically, the RAM (Random Access Memory)
            * idea of RAM is that information can be read and stored in specific places
            (at a particular memory address) and not just sequentially
    1. stack
        * works on the LIFO (Last-In First-Out) scheme
        * when the bytecode starts executing, the Stack is empty
    1. calldata
        * it is a read-only location
        * in principle, the calldata can be anything
        * where call or transaction payload information is stored
            * call payload is usually the signature of the function to be executed, followed by the ABI encoding of the function arguments

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