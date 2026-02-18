// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {
    BalanceDelta,
    BalanceDeltaLibrary
} from "@v4-core/types/BalanceDelta.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary,
    toBeforeSwapDelta
} from "@v4-core/types/BeforeSwapDelta.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ArenaHook
/// @notice Uniswap v4 hook for PvP Trading Arena (Human vs AI & Bot vs Bot)
contract ArenaHook is IHooks, ReentrancyGuard {
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    struct Order {
        address maker;
        bool sellToken0;
        uint128 amountIn;
        uint128 minAmountOut;
        uint256 expiry;
        bool active;
        bytes32 poolId;
        bool isHuman; // New flag for PvP tracking
    }

    // Events
    event OrderPosted(
        uint256 indexed orderId,
        address indexed maker,
        bool isHuman,
        uint128 amountIn,
        uint128 minAmountOut
    );
    event OrderFilled(
        uint256 indexed orderId,
        address indexed taker,
        bool byReactiveAI
    );
    event OrderCancelled(uint256 indexed orderId);

    // Errors
    error NotSentinel();
    error NotWhitelisted();
    error OrderNotFound();
    error OrderNotActive();
    error Unauthorized();
    error InvalidAmounts();

    // State
    IPoolManager public immutable poolManager;
    address public sentinel; // Reactive Network Contract
    mapping(address => bool) public allowedBots; // Whitelist for Bot-vs-Bot mode

    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;
    mapping(bytes32 => uint256[]) public poolOrders;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    modifier onlySentinel() {
        if (msg.sender != sentinel) revert NotSentinel();
        _;
    }

    function setSentinel(address _sentinel) external {
        // TODO: Add admin check
        sentinel = _sentinel;
    }

    // --- Order Board (Battlefield) ---

    // Humans & Bots post orders here
    function postOrder(
        PoolKey calldata key,
        bool sellToken0,
        uint128 amountIn,
        uint128 minAmountOut,
        uint256 duration
    ) external nonReentrant returns (uint256 orderId) {
        if (amountIn == 0) revert InvalidAmounts();

        bytes32 poolId = keccak256(abi.encode(key));
        orderId = nextOrderId++;

        orders[orderId] = Order({
            maker: msg.sender,
            sellToken0: sellToken0,
            amountIn: amountIn,
            minAmountOut: minAmountOut,
            expiry: block.timestamp + duration,
            active: true,
            poolId: poolId,
            isHuman: tx.origin == msg.sender // Simple check: EOA = Human
        });

        // Lock assets
        Currency tokenIn = sellToken0 ? key.currency0 : key.currency1;
        IERC20(Currency.unwrap(tokenIn)).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        poolOrders[poolId].push(orderId);
        emit OrderPosted(
            orderId,
            msg.sender,
            orders[orderId].isHuman,
            amountIn,
            minAmountOut
        );
    }

    // --- Execution Layers ---

    // 1. Reactive AI Trigger (The "Snipe")
    // Called by Reactive Sentinel when L1 conditions are met
    function triggerOrder(
        uint256 orderId,
        address beneficiary
    ) external onlySentinel nonReentrant {
        Order storage order = orders[orderId];
        if (!order.active) revert OrderNotActive();

        // AI "fills" the order by taking the assets and providing the requested out-amount
        // In a real implementation, the Sentinel/AI must provide the swap capital.
        // For Hackathon Demo: We assume the AI has an L2 wallet (beneficiary) that holds funds.

        // ... (Settlement Logic similar to beforeSwap) ...

        order.active = false;
        emit OrderFilled(orderId, beneficiary, true);
    }

    // 2. Standard P2P Match (Bot vs Bot / Human vs Human)
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // ... Ported Claw2Claw Logic ...
        // Iterates poolOrders to find a match
        return (
            IHooks.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    // Boilerplate
    function afterSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4, int128) {
        return (IHooks.afterSwap.selector, 0);
    }
    function beforeInitialize(
        address,
        PoolKey calldata,
        uint160
    ) external pure override returns (bytes4) {
        return IHooks.beforeInitialize.selector;
    }
    function afterInitialize(
        address,
        PoolKey calldata,
        uint160,
        int24
    ) external pure override returns (bytes4) {
        return IHooks.afterInitialize.selector;
    }
    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IHooks.beforeAddLiquidity.selector;
    }
    function afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure override returns (bytes4, BalanceDelta) {
        return IHooks.afterAddLiquidity.selector;
    }
    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IHooks.beforeRemoveLiquidity.selector;
    }
    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure override returns (bytes4, BalanceDelta) {
        return IHooks.afterRemoveLiquidity.selector;
    }
    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IHooks.beforeDonate.selector;
    }
    function afterDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IHooks.afterDonate.selector;
    }
}
