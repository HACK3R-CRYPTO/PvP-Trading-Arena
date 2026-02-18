# PvP Arena Backend (AI Agent) 🧠

This directory will contain the **AI Agent** logic that:

1.  **Monitors** the `ArenaSentinel.sol` contract (and L1 Uniswap v3).
2.  **Analyzes** market conditions for arbitrage opportunities.
3.  **Triggers** the `triggerOrder` function on the L2 `ArenaHook.sol` via the Sentinel.

## Proposed Stack
*   **Language**: TypeScript / Node.js or Python
*   **Libraries**: `viem`, `ethers`, `ccxt` (for CEX price reference)

## Next Steps
*   Initialize project: `npm init -y`
*   Install dependencies: `npm install viem dotenv`
*   Create `agent.ts` to listen for `OrderPosted` events.
