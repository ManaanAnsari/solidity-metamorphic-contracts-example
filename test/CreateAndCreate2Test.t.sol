// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

contract A {
    function kill() public {
        selfdestruct(payable(address(0)));
    }
}

contract DeployUsingCreate {
    address public deployedAddress;

    function deploy() public {
        deployedAddress = address(new A());
    }

    function computeAddress(uint256 _nonce) public view returns (address) {
        address _origin = address(this);
        bytes memory data;
        if (_nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        } else if (_nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        } else if (_nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        } else if (_nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        } else if (_nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        }
        return address(uint160(uint256(keccak256(data))));
    }
}

contract DeployUsingCreate2 {
    address public deployedAddress;
    // Takes a bytes32 string as argument to generate the address the SimpleContract contract will be deployed at.

    function computeAddress(uint256 salt) public view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            bytes32(salt),
                            keccak256(abi.encodePacked(type(A).creationCode, abi.encode()))
                        )
                    )
                )
            )
        );
    }

    function deploy(uint256 salt) public {
        deployedAddress = address(new A{salt: bytes32(salt)}());
    }
}

contract MetamorphicContract is Test {
    DeployUsingCreate private deployUsingCreate;
    DeployUsingCreate2 private deployUsingCreate2;

    function setUp() public {
        deployUsingCreate = new DeployUsingCreate();
        deployUsingCreate2 = new DeployUsingCreate2();
    }

    function testCreateOld() public {
        address expected_address = deployUsingCreate.computeAddress(1);
        deployUsingCreate.deploy();
        assertEq(deployUsingCreate.deployedAddress(), expected_address);
    }

    function testCreate2() public {
        address expected_address = deployUsingCreate2.computeAddress(121);
        deployUsingCreate2.deploy(121);
        assertEq(deployUsingCreate2.deployedAddress(), expected_address);
    }
}
