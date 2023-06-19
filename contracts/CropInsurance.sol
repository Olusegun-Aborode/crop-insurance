//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CropInsurance is Ownable {

  struct Farmer {
    bool isInsured;
    uint256 premium;
    uint256 compensation;
  }

  mapping(address => Farmer) public farmers;

  function insure(address farmerAddress, uint256 premium) public payable onlyOwner {
    require(msg.value == premium, "Transferred amount does not match the premium");
    
    Farmer memory newFarmer;
    newFarmer.isInsured = true;
    newFarmer.premium = premium;
    newFarmer.compensation = 0;

    farmers[farmerAddress] = newFarmer;
  }

  function compensate(address farmerAddress, uint256 amount) public onlyOwner {
    require(farmers[farmerAddress].isInsured == true, "The farmer is not insured");
    
    farmers[farmerAddress].compensation += amount;
    payable(farmerAddress).transfer(amount);
  }
}
