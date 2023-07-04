// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Insurance is ERC20 {
    using SafeMath for uint256;
    IERC20 public immutable cUSD;

    uint256 constant minimumPremium = 50 ether;
    uint256 constant minimumClaimInsurance = 1000 ether;
    uint256 constant tokenRation = 20;

    struct Members {
        uint256 usdValue; 
        uint256 citValue;
        uint256 premi;
        uint256 registerDate;
        uint256 lastPayment;
        uint256 nextPayment;
    }

    mapping(address => Members) private _addressToMembers;
    mapping(address => bool) private _addressStatus;
    mapping (address => uint256[]) private _addressClaimHistory;
    mapping (address => uint256[]) private _addressPaymentHistory;

    event NewRegistration(address indexed members, uint256 timestamp);

    constructor(address _cUSD)ERC20("CropInsuranceToken", "CIT") {
        cUSD = IERC20(_cUSD);
    }

    function register(uint256 _usdAmount) external {
        require(_usdAmount >= minimumPremium, "Insurance: Minimum premium is 50 cUSD");
        require(!_addressStatus[msg.sender], "Insurance: You are already registered");
        cUSD.transferFrom(msg.sender, address(this), _usdAmount);
        uint256 _citAmount = _usdAmount.mul(tokenRation);
        _addressToMembers[msg.sender] = Members(
            _usdAmount,
            _citAmount,
            _usdAmount,
            block.timestamp,
            block.timestamp,
            block.timestamp.add(30 days)
        );
        _addressStatus[msg.sender] = true;
        _addressPaymentHistory[msg.sender].push(block.timestamp);
        _mint(msg.sender, _citAmount);
        emit NewRegistration(msg.sender, block.timestamp);
    }

    function claim(uint256 _citAmount) external {
        require(_citAmount >= minimumClaimInsurance, "Insurance: Minimum claim is 1000 CIT");
        require(_addressStatus[msg.sender], "Insurance: You are not registered");
        uint256 _usdAmount = _citAmount.div(tokenRation);
        Members storage members = _addressToMembers[msg.sender];
        members.usdValue = members.usdValue.sub(_usdAmount);
        members.citValue = members.citValue.sub(_citAmount);
        _addressClaimHistory[msg.sender].push(block.timestamp);
        _burn(msg.sender, _citAmount);
        cUSD.transfer(msg.sender, _usdAmount);
    }

    function pay(uint256 _usdAmount) external {
        require(_addressStatus[msg.sender], "Insurance: You are not registered");
        Members storage members = _addressToMembers[msg.sender];
        require(_usdAmount >= members.premi, "Insurance: Payment amount is less than the premium");
        require(block.timestamp >= members.nextPayment, "Insurance: Payment is not due");
        cUSD.transferFrom(msg.sender, address(this), _usdAmount);
        uint256 _citAmount = _usdAmount.mul(tokenRation);
        members.usdValue = members.usdValue.add(_usdAmount);
        members.citValue = members.citValue.add(_citAmount);
        members.lastPayment = block.timestamp;
        members.nextPayment = block.timestamp.add(30 days);
        _addressPaymentHistory[msg.sender].push(block.timestamp);
        _mint(msg.sender, _citAmount);
    }

    function getInsurance() external view returns (Members memory) {
        return _addressToMembers[msg.sender];
    }
}