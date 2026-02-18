// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive} from "reactive-lib/interfaces/IReactive.sol";

import {
    AbstractReactive
} from "reactive-lib/abstract-base/AbstractReactive.sol";

contract ArenaSentinel is AbstractReactive {
    // --- Configuration ---
    address public constant L1_UNISWAP_V3_POOL =
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // USDC/ETH 5bps on Mainnet (Demo: Sepolia Mock)
    uint256 public constant L1_CHAIN_ID = 11155111; // Sepolia
    uint256 public constant L2_CHAIN_ID = 84532; // Base Sepolia

    // Uniswap v3 Swap Event Signature
    // event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick);
    uint256 public constant SWAP_TOPIC_0 =
        0xc42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67;

    address public arenaHook;
    address public beneficiary; // AI Wallet that receives arb profits

    // Triggers
    struct Trigger {
        bool active;
        bool isLower; // true = trigger usage if price < limit
        uint256 limitPrice; // Simplified price rep
        uint256 orderId;
        address maker;
    }

    // Mapping L1 Pool -> Triggers (Simplified: Global list for hackathon)
    Trigger[] public triggers;

    constructor(address _arenaHook, address _beneficiary) {
        arenaHook = _arenaHook;
        beneficiary = _beneficiary;

        // Subscribe to L1 Uniswap v3 Swaps
        service.subscribe(
            L1_CHAIN_ID,
            L1_UNISWAP_V3_POOL,
            SWAP_TOPIC_0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    // --- AI Strategy Configuration (Called by backend) ---
    function addTrigger(
        uint256 orderId,
        address maker,
        uint256 limitPrice,
        bool isLower
    ) external {
        triggers.push(
            Trigger({
                active: true,
                isLower: isLower,
                limitPrice: limitPrice,
                orderId: orderId,
                maker: maker
            })
        );
    }

    // --- Reactive Loop ---
    // --- Reactive Loop ---
    function react(IReactive.LogRecord calldata log) external override {
        // Only care about our subscription
        if (log.chain_id != L1_CHAIN_ID || log.topic_0 != SWAP_TOPIC_0) return;

        // Decode Sync/Swap data to get price
        // Swap(..., uint160 sqrtPriceX96, ...) is in 'data' (non-indexed args)
        // args: int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick
        (, , uint160 sqrtPriceX96, , ) = abi.decode(
            log.data,
            (int256, int256, uint160, uint128, int24)
        );

        uint256 currentPrice = (uint256(sqrtPriceX96) *
            uint256(sqrtPriceX96) *
            1e18) >> 192; // Rough approx for demo

        // Check triggers
        for (uint256 i = 0; i < triggers.length; i++) {
            Trigger storage t = triggers[i];
            if (!t.active) continue;

            bool hit = t.isLower
                ? (currentPrice < t.limitPrice)
                : (currentPrice > t.limitPrice);

            if (hit) {
                t.active = false; // One-shot

                // Signal L2 Hook to execute
                // Function: triggerOrder(uint256 orderId, address beneficiary)
                bytes memory payload = abi.encodeWithSignature(
                    "triggerOrder(uint256,address)",
                    t.orderId,
                    beneficiary
                );

                emit Callback(L2_CHAIN_ID, arenaHook, 500000, payload);
            }
        }
    }
}
