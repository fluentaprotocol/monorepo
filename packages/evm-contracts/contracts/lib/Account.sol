// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.27;

library Account {
    uint private constant ACCOUNT_SLOT_COUNT = 256;
    string private constant ACCOUNT_NAMESPACE = "fluenta.account";

    /**************************************************************************
     * External functions
     *************************************************************************/
    function account(address owner) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_NAMESPACE, owner));
    }

    function slot(
        address account_,
        uint index
    ) internal pure returns (bytes32) {
        return _slot(account(account_), index);
    }

    function slotIndex(
        address account_,
        bytes32 slot_
    ) internal pure returns (uint) {
        return _slotIndex(account(account_), slot_);
    }

    function isOwner(
        address account_,
        bytes32 slot_
    ) internal pure returns (bool) {
        return _isOwner(account(account_), slot_);
    }

    /**************************************************************************
     * Private functions
     *************************************************************************/
    function _slot(
        bytes32 account_,
        uint index
    ) private pure returns (bytes32 slot_) {
        assembly {
            slot_ := add(account_, add(index, 1))
        }
    }

    function _slotIndex(
        bytes32 account_,
        bytes32 slot_
    ) private pure returns (uint index) {
        if (!_isOwner(account_, slot_)) {
            revert("account does not own slot");
        }

        assembly {
            index := sub(sub(slot_, account_), 1)
        }
    }

    function _isOwner(
        bytes32 account_,
        bytes32 slot_
    ) private pure returns (bool) {
        bytes32 min;
        bytes32 max;
        assembly {
            min := add(account_, 1)
            max := add(account_, add(ACCOUNT_SLOT_COUNT, 1))
        }
        return (slot_ >= min && slot_ <= max);
    }
}
