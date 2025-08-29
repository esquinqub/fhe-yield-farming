// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * FHE Private DeFi Yield Farming (Demo)
 *
 * Purpose: illustrate how a yield farming protocol could store and handle
 * ENCRYPTED values (ciphertext) on an FHE-enabled EVM.
 *
 * Notes:
 * - In a real FHEVM, reward accrual and arithmetic would happen on ciphertext.
 *   Here, ciphertext is represented by `bytes`, and clients/FHE helpers
 *   provide updated ciphertext values; the contract emits events.
 * - Plaintext aggregates below are observable hints; they should not leak
 *   user-private data.
 */
contract YieldFarm {
    // =============================================================
    //                          STRUCTS
    // =============================================================

    /// @dev Minimal farming pool descriptor (simplified for demo)
    struct Pool {
        bytes name;            // can be plaintext or ciphertext label
        uint256 createdAt;
        bool active;
        // Plaintext aggregates (demo-only hints, not actual amounts)
        uint256 farmers;       // number of active addresses
        uint256 deposits;      // number of deposit txs
        uint256 claims;        // number of claim txs
    }

    /// @dev Encrypted farming position of a user in a pool
    struct EncryptedPosition {
        address user;
        bytes encryptedStake;      // ciphertext of staked amount
        bytes encryptedAccrued;    // ciphertext of accrued rewards
        uint256 lastUpdate;
        bool active;
    }

    // =============================================================
    //                           STORAGE
    // =============================================================

    address public owner;

    // poolId => Pool
    mapping(uint256, Pool) public pools;
    uint256 public nextPoolId;

    // poolId => user => position
    mapping(uint256 => mapping(address => EncryptedPosition)) public positions;

    // =============================================================
    //                            EVENTS
    // =============================================================

    event PoolCreated(uint256 indexed poolId, bytes name);
    event PoolStatusChanged(uint256 indexed poolId, bool active);

    event DepositedEncrypted(
        uint256 indexed poolId,
        address indexed user,
        bytes encryptedStake
    );

    event AccruedEncrypted(
        uint256 indexed poolId,
        address indexed user,
        bytes encryptedRewardDelta,
        bytes newEncryptedAccrued
    );

    event ClaimedEncrypted(
        uint256 indexed poolId,
        address indexed user,
        bytes encryptedPayout
    );

    event WithdrawnEncrypted(
        uint256 indexed poolId,
        address indexed user,
        bytes encryptedAmount
    );

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier poolActive(uint256 poolId) {
        require(pools[poolId].active, "Pool inactive");
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor() {
        owner = msg.sender;
    }

    // =============================================================
    //                        ADMIN FUNCTIONS
    // =============================================================

    /// @notice Create a new pool (name can be plaintext or ciphertext)
    function createPool(bytes calldata name) external onlyOwner returns (uint256 id) {
        id = nextPoolId++;
        pools[id] = Pool({
            name: name,
            createdAt: block.timestamp,
            active: true,
            farmers: 0,
            deposits: 0,
            claims: 0
        });
        emit PoolCreated(id, name);
    }

    /// @notice Toggle pool active status
    function setPoolActive(uint256 poolId, bool active_) external onlyOwner {
        pools[poolId].active = active_;
        emit PoolStatusChanged(poolId, active_);
    }

    /// @notice Transfer contract ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    // =============================================================
    //                        USER INTERACTIONS
    // =============================================================

    /**
     * @notice Deposit stake as ciphertext.
     * @param poolId   Target pool
     * @param encStake Ciphertext representing the staked amount
     */
    function depositEncrypted(uint256 poolId, bytes calldata encStake)
        external
        poolActive(poolId)
    {
        EncryptedPosition storage p = positions[poolId][msg.sender];

        // First-time participation in this pool
        if (!p.active) {
            p.user = msg.sender;
            p.active = true;
            pools[poolId].farmers += 1;
        }

        // Overwrite encrypted stake (clients/FHE layer can decide accumulation model)
        p.encryptedStake = encStake;
        p.lastUpdate = block.timestamp;

        pools[poolId].deposits += 1;
        emit DepositedEncrypted(poolId, msg.sender, encStake);
    }

    /**
     * @notice Accrue rewards as ciphertext.
     * @dev In real FHEVM, the ciphertext math happens off/on-chain with FHE.
     *      Here, the client supplies the delta and the new total as ciphertext.
     * @param encRewardDelta  Newly accrued reward (ciphertext)
     * @param newEncAccrued   New total accrued (ciphertext)
     */
    function accrueEncrypted(
        uint256 poolId,
        bytes calldata encRewardDelta,
        bytes calldata newEncAccrued
    ) external poolActive(poolId) {
        EncryptedPosition storage p = positions[poolId][msg.sender];
        require(p.active, "No active position");

        p.encryptedAccrued = newEncAccrued;
        p.lastUpdate = block.timestamp;

        emit AccruedEncrypted(poolId, msg.sender, encRewardDelta, newEncAccrued);
    }

    /**
     * @notice Claim rewards as ciphertext.
     * @dev Contract only records and emits an event. Users decrypt locally.
     * @param encPayout Ciphertext payout
     */
    function claimEncrypted(uint256 poolId, bytes calldata encPayout)
        external
        poolActive(poolId)
    {
        EncryptedPosition storage p = positions[poolId][msg.sender];
        require(p.active, "No active position");

        // Reset accrued after claiming (typical flow)
        p.encryptedAccrued = "";
        pools[poolId].claims += 1;

        emit ClaimedEncrypted(poolId, msg.sender, encPayout);
    }

    /**
     * @notice Withdraw stake as ciphertext (demo: no token transfers here).
     * @dev Marks position inactive, clears ciphertext fields, and emits event.
     */
    function withdrawEncrypted(uint256 poolId, bytes calldata encAmount) external {
        EncryptedPosition storage p = positions[poolId][msg.sender];
        require(p.active, "Already inactive");

        p.active = false;
        p.encryptedStake = "";
        p.encryptedAccrued = "";
        p.lastUpdate = block.timestamp;

        if (pools[poolId].farmers > 0) {
            pools[poolId].farmers -= 1;
        }

        emit WithdrawnEncrypted(poolId, msg.sender, encAmount);
    }

    // =============================================================
    //                            VIEWS
    // =============================================================

    function isActive(uint256 poolId, address user) external view returns (bool) {
        return positions[poolId][user].active;
    }

    function getPoolAggregates(uint256 poolId)
        external
        view
        returns (uint256 farmers, uint256 deposits, uint256 claims)
    {
        Pool storage pl = pools[poolId];
        return (pl.farmers, pl.deposits, pl.claims);
    }
}
