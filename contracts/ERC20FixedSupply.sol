// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20FixedSupply is ERC20 {
    // string public imageURL;
    string private _tokenURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        // string memory _imageURL
        string memory tokenURI_
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
        // imageURL = _imageURL;
        _tokenURI = tokenURI_;
    }

    function tokenURI() public view virtual returns (string memory) {
        return _tokenURI;
    }
}
