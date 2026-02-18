# ⚔️ PvP Trading Arena: Man vs. Machine

## 🚀 The Vision
**PvP Trading Arena** is a decentralized trading platform where **Human Traders** compete against **AI Agents** in a battle for profit.
*   **Humans** place P2P Limit Orders on Layer 2 (Base), hoping to get a specific price.
*   **AI Agents** (powered by **Reactive Network**) watch Layer 1 (Ethereum Mainnet). When the *real* market moves, they "snipe" (fill) the human orders instantly, capitalizing on the latency and price differences.

It's not just a DEX; it's a **Player vs Player game** where the "AI" is a smart contract that reacts to real-world data faster than you ever could.

## 🏗️ Technical Architecture

### 1. The Battlefield: Layer 2 (Base)
*   **Uniswap v4 Hook (`ArenaHook.sol`)**: A unified liquidity layer supporting two modes:
    1.  **Bot vs. Bot (P2P)**: Whitelisted bots trade with each other (Original Claw2Claw logic).
    2.  **Human vs. AI (PvP)**: Humans place orders that are "sniped" by Reactive AI based on L1 signals.
    *   Assets are locked in the Hook for both modes.

### 2. The AI Brain: Reactive Network
*   **Reactive Sentinel (`ArenaSentinel.sol`)**: A smart contract that lives on the Reactive Network.
    *   It **listens** to the "Real Price" on Ethereum Layer 1 (Uniswap v3 pools).
    *   When the L1 price creates an arbitrage opportunity (e.g., ETH hits $3010), it **fires a signal** to L2.

### 3. The Execution: Cross-Chain
*   The `Sentinel` on Reactive Network sends a message to the `Hook` on Base.
*   The `Hook` receives the message and **force-fills** the Human's order.
*   **Result**: The Human gets their trade filled, and the AI (or the protocol) captures the arbitrage profit.

## 🛠️ Stack
*   **Layer 1 (Trigger)**: Ethereum Sepolia (Uniswap v3)
*   **Reactive Network**: Reactive Kopli (Sentinel Contract)
*   **Layer 2 (Execution)**: Base Sepolia (Uniswap v4 Hook)
*   **Frontend**: Next.js (The User Interface)
