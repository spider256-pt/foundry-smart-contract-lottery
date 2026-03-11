# 🎲 Provably Fair Decentralized Lottery (Foundry)

An automated, decentralized, and mathematically provably fair smart contract lottery built with the Foundry framework. This protocol leverages **Chainlink VRF** for secure, tamper-proof randomness and **Chainlink Automation** for decentralized, trustless execution.



## 🏗 Architecture & Deep Logic

This codebase is structured with a strict separation of concerns, designed for professional auditing and scalable deployments:

* **The Engine (`src/Raffle.sol`):** The core state machine. Handles player entry, balance management, and the cryptographic handshake with Chainlink VRF. 
* **The Factory (`script/DeployRaffle.s.sol`):** The automated deployment pipeline. Injects environment-specific variables into the core engine.
* **The Environment Map (`script/HelperConfig.s.sol`):** Dynamic routing. Automatically detects the current chain (Anvil, Sepolia, or Mainnet) and supplies the correct Mock or Live contract addresses.
* **The Remote Control (`script/Interaction.s.sol`):** Programmatic automation. Contains dedicated bots to programmatically bypass UI requirements (Creating, Funding, and Adding Consumers to Chainlink VRF subscriptions).

## 🛡️ Security & Testing Methodology

Built with an offensive security mindset. The testing suite utilizes the Arrange, Act, Assert (AAA) pattern and heavy EVM state manipulation to ensure bulletproof business logic.

* **State Manipulation:** Extensive use of Foundry cheatcodes (`vm.warp`, `vm.roll`, `vm.prank`) to test boundary conditions and edge cases.
* **Execution Tracing:** Tests are designed to be debugged using deep EVM execution traces (`-vvv` and `-vvvv`).
* **Revert Validations:** Strict enforcement of custom errors using `vm.expectRevert` to prevent unexpected state transitions.
* **Event Monitoring:** Validating frontend-facing data logs using `vm.expectEmit`.

## ⚙️ Quick Start

### Prerequisites
* [Git](https://git-scm.com/)
* [Foundry](https://getfoundry.sh/) (forge, cast, anvil, chisel)

### Installation

1. Clone the repository:
```bash
git clone [https://github.com/spider256-pt/foundry-smart-contract-lottery.git](https://github.com/spider256-pt/foundry-smart-contract-lottery.git)
cd foundry-smart-contract-lottery
