// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "./ERC721.sol";
import {Any721Socket} from "./Any721Socket.sol";

contract Guardian is ERC721 {
    constructor() ERC721("Guardian", "Guardian") {}

    function setSocket(address socket) public {
        require(minter == address(0) && superowner == address(0));
        minter = socket;
        superowner = socket;
    }

    address public minter;

    modifier onlyMinter() {
        require(_msgSender() == minter, "");
        _;
    }

    function safeMint(address to, uint256 tokenId) external onlyMinter {
        _safeMint(to, tokenId);
    }

    // superowner can edit attributes of his tokens
    address public superowner;

    modifier onlySuperowner(uint256 tokenId) {
        require(_msgSender() == superowner, "Must be called by superowner");
        require(ownerOf(tokenId) == superowner, "Must own this token");
        _;
    }

    function claim(uint256 tokenId) public {
        _safeMint(msg.sender, tokenId);
    }

    mapping(uint256 => uint) private aura;

    function Aura(uint256 tokenId) public view returns (uint) {
        return aura[tokenId];
    }

    function SetAura(uint256 tokenId, uint _aura) public onlySuperowner(tokenId) {
        aura[tokenId] = _aura;
    }
}

contract AnyGuardianSocket is Any721Socket {
    constructor (address router, address underlying) Any721Socket(router, underlying) {}

    function packAttributes(uint256 tokenId) override public view returns (string memory data) {
        uint aura = Guardian(underlying).Aura(tokenId);
        data = string(abi.encodePacked(data, aura));
        return data;
    }

    /*
    [0,1000]
    // ordered list, [element,aura]
    */
    function recoverAttributes(uint256 tokenId, string calldata data) override internal {    
        uint aura = uint(parseInt(data));

        Guardian(underlying).SetAura(tokenId, aura);
        emit LogSetGuardian(tokenId, aura);
        return;
    }

    event LogSetGuardian(uint256 tokenId, uint aura);

    function parseInt(string memory _a) internal pure returns (int) {
        bytes memory bresult = bytes(_a);
        int mint = 0;
        bool negative = false;
        for (uint i=0; i<bresult.length; i++){
            if ((i == 0) && (bresult[i] == '-')) {
                negative = true;
            }
            mint *= 10;
            uint x = uint8(bresult[i]);
            mint += int256(x) - 48;
        }
        if (negative) mint *= -1;
        return mint;
    }
}