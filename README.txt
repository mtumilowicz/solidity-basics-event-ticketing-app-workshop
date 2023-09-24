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
            * adds a byte to the Stack.
            * The `PUSH1` opcode is an operator that expects a 1-byte operand
            * Then the complete statement is `60 01`
        * `60 02` // similar
        * final result: number 3 on the Stack
        * digression
            * byte 01 was used both as an operand and operator
            * it’s easy to figure out what it represents in the context of how it was used
* is a transaction-based state machine
    * execution history is stored on the blockchain, making it immutable and transparent
    * incrementally execute transactions, which morph into some new state
        * each transaction on a blockchain is a transition of state

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