// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

contract A {
    function kill() public {
        selfdestruct(payable(address(0)));
    }
}

contract B {
    uint256 private x;

    constructor(uint256 x_) {
        x = x_;
    }
}

contract Factory {
    function helloA() public returns (address) {
        return address(new A());
    }

    function helloB() public returns (address) {
        return address(new B(1337));
    }

    function kill() public {
        selfdestruct(payable(address(0)));
    }
}

contract MetamorphicContract is Test {
    A private a;
    B private b;
    Factory private factory;

    function setUp() public {
        factory = new Factory{salt: keccak256(abi.encode("evil"))}();
        a = A(factory.helloA());

        /// @dev Call `selfdestruct` during the `setUp` call (see https://github.com/foundry-rs/foundry/issues/1543).
        a.kill();
        factory.kill();
    }

    function testMorphingContract() public {
        /// @dev Verify that the code was destroyed during the `setUp` call.
        assertEq(address(a).code.length, 0);
        assertEq(address(factory).code.length, 0);

        /// @dev Redeploy the factory contract at the same address.
        factory = new Factory{salt: keccak256(abi.encode("evil"))}();
        /// @dev Deploy another logic contract at the same address as previously contract `a`.
        b = B(factory.helloB());
        assertEq(address(a), address(b));
    }
}
