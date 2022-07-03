//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./Contracts.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract Tokenization is Ownable, IERC721, ERC165 {
    using SafeMath for uint;

    bytes32 hashTokenPackages;
    uint redemptionTime;
    mapping (uint => address) packageApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;
    address[] packageOwner;
    mapping (address => uint) ownerPackageCount;
    mapping (address => uint) ownerPaid;
    address[] owners;
    uint[] tokenIncome;
    bool[] isNotDefault;
    bool completed;


    constructor(bytes32 _hashTokenPackages, uint _redemptionTime, address[] memory _packageOwner, uint[] memory _tokenIncome) {
        hashTokenPackages = _hashTokenPackages;
        redemptionTime = _redemptionTime;
        packageOwner = _packageOwner;
        tokenIncome = _tokenIncome;
        for (uint i = 0; i < packageOwner.length; i++) {
            ownerPackageCount[packageOwner[i]] = ownerPackageCount[packageOwner[i]].add(1);
            if (ownerPackageCount[packageOwner[i]] == 1) {
                owners.push(packageOwner[i]);
            }
        }
    }


    /*
    modifier onlyOwnerOf(uint _tokenId) {
      require(msg.sender == packageOwner[_tokenId]);
      _;
    }
    */


    function balanceOf(address _owner) public view override returns (uint) {
        return ownerPackageCount[_owner];
    }


    function ownerOf(uint _tokenId) public view override returns (address) {
        return packageOwner[_tokenId];
    }


    function _transfer(address _from, address _to, uint _tokenId) internal {
        ownerPackageCount[_to] = ownerPackageCount[_to].add(1);
        ownerPackageCount[msg.sender] = ownerPackageCount[msg.sender].sub(1);
        packageOwner[_tokenId] = _to;
        packageApprovals[_tokenId] = address(0);
        emit Transfer(_from, _to, _tokenId);
    }


    function transferFrom(address _from, address _to, uint _tokenId) public override {
        require (_tokenId < packageOwner.length && _from == ownerOf(_tokenId) && _to != address(0));
        require (packageOwner[_tokenId] == msg.sender || packageApprovals[_tokenId] == msg.sender || operatorApprovals[ownerOf(_tokenId)][msg.sender]);
        _transfer(_from, _to, _tokenId);
    }


    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data) public override {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, data));
    }


    function safeTransferFrom(address _from, address _to, uint _tokenId) public override {
        safeTransferFrom(_from, _to, _tokenId);
    }


    function approve(address _approved, uint _tokenId) public override {
        require(packageOwner[_tokenId] == msg.sender);
        packageApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }


    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        require(_tokenId < packageOwner.length);
        return packageApprovals[_tokenId];
    }


    function setApprovalForAll(address _operator, bool _approved) public override {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }


    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return operatorApprovals[_owner][_operator];
    }


    function payReward(bool[] memory _isNotDefault, uint[][] memory tokenPackages, uint nonce) public payable onlyOwner {
        bytes memory nonceBytes = new bytes(32);
        assembly { mstore(add(nonceBytes, 32), nonce) }
        require(keccak256(nonceBytes) == hashTokenPackages, string(nonceBytes));
        isNotDefault = _isNotDefault;
        uint income = 0;
        for (uint j; j < packageOwner.length; j++) {
            uint payoutSum = 0;
            for (uint i; i < tokenIncome.length; i++) {
                payoutSum = payoutSum.add(tokenPackages[i][j] * tokenIncome[i] * (isNotDefault[i] ? 1 : 0));
            }
            ownerPaid[packageOwner[j]] = ownerPaid[packageOwner[j]].add(payoutSum);
            income = income.add(payoutSum);
        }
        require(msg.value == income);
        for (uint i; i < owners.length; i++) {
            payable(owners[i]).transfer(ownerPaid[owners[i]]);
        }
        completed = true;
    }


    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


    /*
    function _isReady() internal pure returns (bool) {
      return (now <= redemptionTime);
    }

    function retrieveIncome() public {
        require (ownerPackagePaid[msg.sender] == false && ownerPackageCount[msg.sender] > 0 && _isReady());
        for (uint i = 0; i < packageOwner.length; i++) {
            if (packageOwner[i] == msg.sender):
                _payIncome(i, msg.sender);
        }
    }
    */
}
