pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  //state variables 
  mapping (address => mapping (address => uint256)) private _allowances;


  // IERC20

  function allowance(address owner, address spender) external view override returns (uint256) {
    //return from list of known allowances
    return _allowances[owner][spender];
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    //call private transfer function 
    return _transfer(msg.sender, to, value);
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    //approve by adding to list of known allowances
    _allowances[msg.sender][spender] = value;
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(_allowances[from][msg.sender] >= value, "Insufficient allowance");
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  // IMintableToken

  function mint() external payable override {
    require(msg.value > 0, "Must send ETH to mint");

    balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
    totalSupply = totalSupply.add(msg.value);
  }

  function burn(address payable dest) external override {
    uint256 amount = balanceOf[msg.sender];
    require(amount > 0, "No tokens to burn");

    balanceOf[msg.sender] = 0;
    totalSupply = totalSupply.sub(amount);

    // Transfer ETH to destination
    dest.transfer(amount);
  }

  // IDividends

  function getNumTokenHolders() external view override returns (uint256) {
    revert();
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    revert();
  }

  function recordDividend() external payable override {
    revert();
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    revert();
  }

  function withdrawDividend(address payable dest) external override {
    revert();
  }

  function _transfer(address from, address to, uint256 value) internal returns (bool) {
    require(balanceOf[from] >= value, "Insufficient balance");

    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);

    return true;
  }
}