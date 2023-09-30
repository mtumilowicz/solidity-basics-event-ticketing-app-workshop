# solidity-basics-event-ticketing-app-workshop

* references
    * https://www.investopedia.com/terms/b/basic-attention-token.asp
    * https://ethereum.stackexchange.com/questions/872/what-is-the-cost-to-store-1kb-10kb-100kb-worth-of-data-into-the-ethereum-block
    * https://medium.com/@danielyamagata/understand-evm-opcodes-write-better-smart-contracts-e64f017b619
    * https://ethereum.stackexchange.com/questions/594/how-do-gas-refunds-work
    * https://ethereum.stackexchange.com/questions/92965/how-are-gas-refunds-payed
    * https://ethereum.stackexchange.com/questions/125028/is-there-still-gas-refund-for-sstore-to-0-instructions
    * https://ethereum.stackexchange.com/questions/3/what-is-meant-by-the-term-gas
    * https://ethereum.stackexchange.com/questions/117100/why-do-many-solidity-projects-prefer-importing-specific-names-over-whole-modules
    * https://medium.com/@eiki1212/what-is-ethereum-gas-simple-explanation-2f0ae62ed69c

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
                * protocol achieves an equilibrium block size of 15 million on average through the process of tâtonnement
                * if the block size is greater than the target block size, the protocol will increase the base fee for the following block
                * the protocol will decrease the base fee if the block size is less than the target block size
                * maximum size: 30 million gas (2x the target block size)
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

## gas
* is a measure of computational work required to execute operations or transactions on the network
    * opcodes have a base gas cost used to pay for executing the transaction
        * example: KECCAK256
            * cost: 30 + 6 for every 256 bits of data being hashed
    * there isn't any actual token for gas
        * example: you can't own 1000 gas
        * exists only inside of the Ethereum virtual machine as a count of how much work is being performed
* is the fee paid for executing transactions on the Ethereum blockchain
    * example
        * simple transaction of moving ETH between two addresses
        * we know that this transaction requires 21,000 units
        * base fee for standard speed at the moment of writing is 20 gwei
        * gas fee = gas units (limit) * gas price per unit (in gwei)
        * 21,000 * 20 = 420,000 gwei
        * 420,000 gwei is 0.00042 ETH, which is at the current prices 0.63 USD (1 ETH = $1500)
* gas prices change constantly and there are a number of websites where you can check the current price
    * https://etherscan.io/gastracker
* if Ether (ETH) was directly used as the unit of transaction cost instead of gas, it would lead to several potential problems:
    * reduced flexibility
        * gas allows for adjustments to the cost of computation without affecting the underlying value of Ether
        * if Ether were used directly
            * any change in pricing would directly impact the value of the cryptocurrency
            * it would be difficult to prevent attackers from flooding the network with low-cost transactions
            * cost of computation should not go up or down just because the price of ether changes
                * it's helpful to separate out the price of computation from the price of the ether token
    * difficulty in predictability
        * Ether's value can be volatile, which means that transaction costs would fluctuate with the market price
        * this could lead to unpredictable costs for users and could make it more challenging to budget for transactions
* is used to
    * prevent infinite loops
    * computational resource exhaustion
    * prioritize transactions on the network
    * prevent Sybil attacks
        * by discouraging the creation of a large number of malicious identities
        * solution: prevents an attacker from overwhelming the network with a massive number of transactions
            * as each transaction costs some amount of gas
    * solve halting problem
        * problem = it's generally impossible to determine whether that program will eventually halt or continue running indefinitely
        * solution: program will eventually run out of gas and the transaction will be reverted
* gas has a price, denominated in ether (ETH)
    * users set the gas price they are willing to pay to have their transaction or smart contract executed
    * miners prioritize transactions with higher gas prices because they earn the fees associated with the gas
    * analogy
        * gas price as the hourly wage for the miner
        * gas cost as their timesheet of work performed
* every operation consumes a certain amount of gas
    * is paid by users to compensate miners for the computational work they perform
    * total gas fee = gas used * gas price
* each block has a gas limit
    * maximum amount of gas that can be consumed in a block
    * transaction sender is refunded the difference between the max fee and the sum of the base fee and tip
* some operations can result in a gas refund
    * example: if a smart contract deletes a storage slot, it gets a gas refund
        * digression
            * London Upgrade through EIP-3529: remove gas refunds for `SELFDESTRUCT`, and reduce gas refunds for `SSTORE` to a lower level
    * refund is only applied at the end of the transaction
        * the full gas must be made available in order to execute the full transaction
* it's important to estimate the gas needed for a transaction or smart contract execution
    * if too small => the operation will be reverted and any state changes will be discarded
        * miner still includes it in the blockchain as a "failed transaction", collecting the fees for it
            * sender still pays for the gas consumed up to that point
            * the real work for the miner was in performing the computation
                * they will never get those resources back either
                * it's only fair that you pay them for the work they did, even though your badly designed transaction ran out of gas
    * if too big => the excess gas is refunded (refund = max fee - base fee + tip)
        * max fee (maxFeePerGas)
            * maximum limit to pay for their transaction to be executed
            * must exceed the sum of the base fee and the tip
        * providing too big of a fee is also different than providing too much ether
            * if you set a very high gas price, you will end up paying lots of ether for only a few operations
                * similar to super high transaction fee in bitcoin
            * if you provided a normal gas price, however, and just attached more ether than was needed to pay for the gas that your transaction consumed
                * excess amount will be refunded back to you
                * miners only charge you for the work that they actually do
* EIP-1559
    * implemented in the London Hard Fork upgrade
    * went live in August 2021
    * introduces a new fee structure that separates transaction fees
        * NOT designed to lower gas fees but to make them more transparent and predictable
        * two components
            * base fee
                * minimum fee required to include a transaction in a block
                * determined by network congestion
                    * example
                        * when the network is busy, the base fee increases
                        * when it's less congested, the base fee decreases
                    * increase/decrease is predictable and will be the same for all users
                    * removing the need for each and every wallets to generate their own individual gas estimation strategies
                * is burned
                    * removed from circulation
                    * reducing the overall supply of Ether
                    * miners have less control over manipulating transaction fees
                        * no reason into bumping base price by putting load on the network
                    * benefits all Ether holders equally, rather than exclusively benefiting validators
                        * creates what EIP-1559 coordinator Tim Beiko refers to as an “ETH buyback” mechanism
                        * ETH is paid back to the protocol and the supply gets reduced
            * priority fee
                * optional tip to incentivize miners to include their transaction in the next block
                * goes directly to the miner
    * similar to a delivery service
        * lower fee for regular delivery or a higher fee for express delivery
        * during busy times, like the holiday season, the delivery service may increase the standard delivery fee
            * increase will be set by the delivery company and will affect all customers equally
    * comparable to Bitcoin’s difficulty adjustment
    * oracles might run into issues under EIP-1559 during periods of high congestion
        * they need to provide the pricing information for nearly all of DeFi
        * might end up paying incredibly high fees in order to ensure the pricing information reaches the DeFi application in a timely manner
    * context: original Ethereum gas fee system
        * simple auction system: unpredictable and inefficient
            * users bid a random amount of money to pay for each transaction
                * we can see a large divergence of transaction fees paid by different users in a single block
                    * many users often overpay by more than 5x
                    * example
                        ![alt text](img/pre_eip1559_overpay.png)
            * when the network becomes busy, this system causes gas fees to become high and unpredictable
            * not easy to quick-fix
                * possible improvement: users submit bids as normal, then everyone pays only the lowest bid that was included in the block
                    * can be easily gamed by miners who will fill up their own blocks in order to increase the minimum fee
                    * gameable by transaction senders who collude with miners
        * similar to the way ride-sharing services calculate ride fees
            * when demand for rides is higher, prices go up for everyone who wants a ride
        * problem: Ethereum network becomes busy
            * example
                * CryptoKitty users have reached in excess of 1.5 million(25% of total Ethereal traffic in peak times)
                * trade on a new decentralized cryptocurrency exchange
            * result: users trying to push their transactions by paying absurdly high gas fees
                * gas fees become unpredictable
                * users must guess how much to pay for a transaction
        * as Ethereum has gained new users, the network has become more congested
            * gas fees have become more volatile
            * many users have inadvertently overpaid for their transactions


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