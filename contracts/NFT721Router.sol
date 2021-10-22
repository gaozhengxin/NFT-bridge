// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import {Any721Socket} from "./Any721Socket.sol";

// MPC management means multi-party validation.
// MPC signing likes Multi-Signature is more secure than use private key directly.
contract MPCManageable {
    address public mpc;
    address public pendingMPC;

    uint256 public constant delay = 2*24*3600;
    uint256 public delayMPC;

    modifier onlyMPC() {
        require(msg.sender == mpc, "MPC: only mpc");
        _;
    }

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed effectiveTime);

    event LogApplyMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed applyTime);

    constructor(address _mpc) {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        mpc = _mpc;
        emit LogChangeMPC(address(0), mpc, block.timestamp);
    }

    function changeMPC(address _mpc) external onlyMPC {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        pendingMPC = _mpc;
        delayMPC = block.timestamp + delay;
        emit LogChangeMPC(mpc, pendingMPC, delayMPC);
    }

    function applyMPC() external {
        require(msg.sender == pendingMPC, "MPC: only pendingMPC");
        require(block.timestamp >= delayMPC, "MPC: time before delayMPC");
        emit LogApplyMPC(mpc, pendingMPC, block.timestamp);
        mpc = pendingMPC;
        pendingMPC = address(0);
        delayMPC = 0;
    }
}

interface IERC721Transfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155Transfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract NFTRouter is MPCManageable {
    uint256 public immutable cID;

    constructor(
        address _mpc
    ) MPCManageable(_mpc) {
        uint256 chainID;
        assembly {chainID := chainid()}
        cID = chainID;
    }

    mapping(address => address) public nftSockets;

    function registerToken(address token, address socket) external onlyMPC {
        require(Any721Socket(socket).underlying() == token);
        emit LogRegisterToken(token, socket);
        nftSockets[token] = socket;
    }

    // swapin `tokenId` of `token` in `fromChainID` to recipient `to` on this chainID
    // SwapIn = LockOut
    function nft721SwapIn(
        bytes32 txHash,
        address token,
        address to,
        uint256 tokenId,
        uint256 fromChainID,
        string calldata data
    ) external onlyMPC {
        Any721Socket(nftSockets[token]).LockOut(to, tokenId, data);
        emit LogNFT721SwapIn(txHash, token, to, tokenId, fromChainID, cID, data);
    }

    // swapout `tokenId` of `token` from this chain to `toChainID` chain with recipient `to`
    // SwapOut = LockIn
    function nft721SwapOut(
        address token,
        address to,
        uint256 tokenId,
        uint256 toChainID
    ) external {
        string memory data = Any721Socket(nftSockets[token]).LockIn(msg.sender, tokenId);
        require(tokenId == 112233, "12345678");
        require(false, string(data));
        emit LogNFT721SwapOut(token, msg.sender, to, tokenId, cID, toChainID, bytes(data));
    }

    // make this router contract can receive erc721 token
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return NFTRouter.onERC721Received.selector;
    }

    event LogNFT721SwapIn(
        bytes32 indexed txHash,
        address indexed tokenSocket,
        address indexed to,
        uint256 tokenId,
        uint256 fromChainID,
        uint256 toChainID,
        string data);

    event LogNFT721SwapOut(
        address indexed tokenSocket,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 fromChainID,
        uint256 toChainID,
        bytes data);

    event LogRegisterToken(
        address indexed token,
        address indexed socket);
}
