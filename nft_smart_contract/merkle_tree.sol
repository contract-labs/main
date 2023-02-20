//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/sueun-dev/staking_contract/blob/main/ERC20_staking";

contract Whitelist is Ownable{
    struct Node {
    bytes32 left;
    bytes32 right;
    }

    mapping(bytes32 => Node) public tree;
    bytes32[] public leaves;

    function addToWhitelist(address[] memory addrArray) public onlyOwner {
        for (uint i = 0; i < addrArray.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(addrArray[i]));
            leaves.push(leaf);
        }
        buildTree();
    }

    function removeFromWhitelist(address[] memory addrArray) public onlyOwner {
        for (uint i = 0; i < addrArray.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(addrArray[i]));
            for (uint j = 0; j < leaves.length; j++) {
                if (leaves[j] == leaf) {
                    delete leaves[j];
                }
            }
        }
        buildTree();
    }

    function buildTree() public onlyOwner {
        uint leafCount = leaves.length;
        for (uint i = 0; i < leafCount; i += 2) {
            bytes32 left = leaves[i];
            bytes32 right = leaves[i + 1];
            bytes32 node = keccak256(abi.encodePacked(left, right));
            tree[node] = Node(left, right);
        }
    }

    /*
    예시)
    In the isWhitelisted function, the given address is converted into a bytes32 type using the keccak256 hash function,
    and then it checks whether the value exists in the tree mapping. If it exists, the function returns true; otherwise, it returns false.

    in the code call isWhitelisted "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", 
        but in the ddToWhitelist function ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
        "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"], both address have.
        and this buildTree function make up Merkle Tree using addess in leaves's array

    so, "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db" address has been added.

    */

    function isWhitelisted(address addr) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        bytes32 node = leaf;
        while (tree[node].left != bytes32(0) && tree[node].right != bytes32(0)) {
            if (leaf == tree[node].left) {
                node = keccak256(abi.encodePacked(tree[node].left, tree[node].right));
            } else {
                node = keccak256(abi.encodePacked(tree[node].right, tree[node].left));
            }
        }
        return node == leaves[0];
    }

    function isAddressInWhitelist(address addr) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        for(uint i = 0; i < leaves.length; i++){
            if(leaves[i] == leaf){
                return true;
            }
        }
        return false;
    }

}
