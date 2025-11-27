// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DECENTRA
 * @dev Minimal decentralized registry with role-based access control
 * @notice Community members can register items, while curators and admins manage verification
 */
contract DECENTRA {
    
    // Roles
    bytes32 public constant ROLE_ADMIN   = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_CURATOR = keccak256("ROLE_CURATOR");
    
    // State
    address public owner;
    
    struct RegistryItem {
        address submitter;
        string  uri;        // metadata URI or IPFS/CID
        string  category;   // e.g. "dapp", "community", "asset"
        uint256 createdAt;
        bool    isVerified;
        bool    isActive;
    }
    
    uint256 public totalItems;
    
    // id => item
    mapping(uint256 => RegistryItem) public items;
    
    // account => role => hasRole
    mapping(address => mapping(bytes32 => bool)) public hasRole;
    
    // submitter => itemIds
    mapping(address => uint256[]) public itemsOf;
    
    // Events
    event ItemRegistered(
        uint256 indexed itemId,
        address indexed submitter,
        string uri,
        string category,
        uint256 timestamp
    );
    
    event ItemStatusUpdated(
        uint256 indexed itemId,
        bool isVerified,
        bool isActive,
        uint256 timestamp
    );
    
    event RoleGranted(address indexed account, bytes32 indexed role, address indexed sender);
    event RoleRevoked(address indexed account, bytes32 indexed role, address indexed sender);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier onlyRole(bytes32 role) {
        require(hasRole[msg.sender][role], "Missing role");
        _;
    }
    
    modifier itemExists(uint256 itemId) {
        require(items[itemId].submitter != address(0), "Item does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // bootstrap: owner is ADMIN
        hasRole[msg.sender][ROLE_ADMIN] = true;
        emit RoleGranted(msg.sender, ROLE_ADMIN, msg.sender);
    }
    
    /**
     * @dev Function 1: Register a new item into the decentralized registry
     * @param uri Off-chain metadata or content reference
     * @param category Classification label for the item
     */
    function registerItem(string calldata uri, string calldata category)
        external
        returns (uint256 itemId)
    {
        require(bytes(uri).length > 0, "URI required");
        
        itemId = totalItems;
        totalItems += 1;
        
        items[itemId] = RegistryItem({
            submitter: msg.sender,
            uri: uri,
            category: category,
            createdAt: block.timestamp,
            isVerified: false,
            isActive: true
        });
        
        itemsOf[msg.sender].push(itemId);
        
        emit ItemRegistered(
            itemId,
            msg.sender,
            uri,
            category,
            block.timestamp
        );
    }
    
    /**
     * @dev Function 2: Curator verifies or toggles active status of an item
     * @param itemId Item identifier
     * @param verified New verification state
     * @param active New active state
     * @notice Only accounts with CURATOR role can moderate items
     */
    function moderateItem(
        uint256 itemId,
        bool verified,
        bool active
    )
        external
        itemExists(itemId)
        onlyRole(ROLE_CURATOR)
    {
        RegistryItem storage it = items[itemId];
        it.isVerified = verified;
        it.isActive   = active;
        
        emit ItemStatusUpdated(
            itemId,
            verified,
            active,
            block.timestamp
        );
    }
    
    /**
     * @dev Function 3: Submitter can deactivate their own item
     * @param itemId Item identifier
     */
    function deactivateOwnItem(uint256 itemId)
        external
        itemExists(itemId)
    {
        RegistryItem storage it = items[itemId];
        require(it.submitter == msg.sender, "Not submitter");
        require(it.isActive, "Already inactive");
        
        it.isActive = false;
        
        emit ItemStatusUpdated(
            itemId,
            it.isVerified,
            false,
            block.timestamp
        );
    }
    
    /**
     * @dev Function 4: Grant a role to an account
     * @param account Address to grant role
     * @param role Role identifier (ROLE_ADMIN or ROLE_CURATOR)
     * @notice Only ADMINs can manage roles
     */
    function grantRole(address account, bytes32 role)
        external
        onlyRole(ROLE_ADMIN)
    {
        require(account != address(0), "Zero address");
        require(!hasRole[account][role], "Already has role");
        
        hasRole[account][role] = true;
        emit RoleGranted(account, role, msg.sender);
    }
    
    /**
     * @dev Function 5: Revoke a role from an account
     * @param account Address to revoke role from
     * @param role Role identifier
     * @notice Only ADMINs can manage roles
     */
    function revokeRole(address account, bytes32 role)
        external
        onlyRole(ROLE_ADMIN)
    {
        require(hasRole[account][role], "Role not set");
        
        hasRole[account][role] = false;
        emit RoleRevoked(account, role, msg.sender);
    }
    
    /**
     * @dev Function 6: Transfer contract ownership
     * @param newOwner New owner address
     * @notice Does not automatically change ADMIN role; manage roles separately if needed
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
    
    /**
     * @dev View helper: get item details
     * @param itemId Item identifier
     */
    function getItem(uint256 itemId)
        external
        view
        itemExists(itemId)
        returns (
            address submitter,
            string memory uri,
            string memory category,
            uint256 createdAt,
            bool isVerified,
            bool isActive
        )
    {
        RegistryItem memory it = items[itemId];
        return (
            it.submitter,
            it.uri,
            it.category,
            it.createdAt,
            it.isVerified,
            it.isActive
        );
    }
    
    /**
     * @dev View helper: get all item IDs submitted by a user
     * @param user Address to query
     */
    function getItemsOf(address user) external view returns (uint256[] memory) {
        return itemsOf[user];
    }
}
