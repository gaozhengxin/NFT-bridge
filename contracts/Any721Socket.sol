// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721,Context} from "./ERC721.sol";

interface IERC721Mintable is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
}

abstract contract Any721Socket is Context {
    address public immutable router;
    address public immutable underlying;

    constructor(address _router, address _underlying) Context() {
        router = _router;
        underlying = _underlying;
    }

    modifier onlyRouter() {
        //require (_msgSender() == router, "Any721 Forbidden");
        _;
    }

    function _safeMint(address to, uint256 tokenId) internal {
        IERC721Mintable(underlying).safeMint(to, tokenId);
    }

    /*
    packAttributes should get all attributes of an NFT
    that is needed to recover the same NFT on other chains
    and encode them into bytes
     */
    function packAttributes(uint256 tokenId) public view virtual returns (string calldata);

    /*
    recoverAttributes should take a piece of data
    and decode it into the attributes of the NFT
    recoverAttributes requires Any721Socket to have the authority
    to edit NFT
    */
    function recoverAttributes(uint256 tokenId, string calldata data) internal virtual;

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        try IERC721(underlying).ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function LockOut(
        address to,
        uint256 tokenId,
        string calldata data
    ) external onlyRouter {
        require(to != router && to != address(this));
        if (!_exists(tokenId)) {
            _safeMint(address(this), tokenId);
        }
        recoverAttributes(tokenId, data);
        IERC721(underlying).safeTransferFrom(address(this), to, tokenId);
    }

    function LockIn(
        address _from,
        uint256 tokenId
    ) external onlyRouter returns (string memory data) {
        data = this.packAttributes(tokenId);
        IERC721(underlying).safeTransferFrom(_from, address(this), tokenId);
        return data;
    }
    
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return Any721Socket.onERC721Received.selector;
    }
}