//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

/**
 * @title Token
 * @author John R. Kosinski
 * @notice A mintable and burnable ERC20 token with dividend distribution functionality
 * @dev This contract implements:
 *      - ERC20 standard token functionality (transfer, approve, transferFrom)
 *      - Minting mechanism where users can mint tokens by sending ETH (1:1 ratio)
 *      - Burning mechanism where users can burn tokens to receive ETH back
 *      - Dividend distribution system that allows proportional ETH distributions to token holders
 *      - Automatic tracking of token holders for dividend calculations
 */
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
  mapping (address => uint256) private holderIndex; //1-based index, 0 means not in list
  address[] private holders;
  mapping (address => uint256) private dividends;

  // ERC20 Events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


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
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(_allowances[from][msg.sender] >= value, "Insufficient allowance");
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    return _transfer(from, to, value);
  }

  // IMintableToken

  function mint() external payable override {
    _mint(msg.sender, msg.value);
  }

  function burn(address payable dest) external override {
    uint256 amount = balanceOf[msg.sender];
    require(amount > 0, "No tokens to burn");

    balanceOf[msg.sender] = 0;
    totalSupply = totalSupply.sub(amount);

    //update holder list
    _updateHolderList(msg.sender);

    //transfer ETH to destination
    dest.transfer(amount);

    //emit event for ERC20-compliance
    emit Transfer(msg.sender, address(0), amount);
  }

  receive() external payable {
    _mint(msg.sender, msg.value);
  }

  // IDividends

  function getNumTokenHolders() external view override returns (uint256) {
    return holders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    require(index > 0 && index <= holders.length, "Index out of bounds");
    return holders[index - 1];
  }

  function recordDividend() external payable override {
    require(msg.value > 0, "Must send ETH as dividend");

    //distribute dividend proportionally to all current holders
    for (uint256 i = 0; i < holders.length; i++) {
      address holder = holders[i];
      uint256 holderBalance = balanceOf[holder];
      uint256 holderDividend = msg.value.mul(holderBalance).div(totalSupply);
      dividends[holder] = dividends[holder].add(holderDividend);
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return dividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount = dividends[msg.sender];
    require(amount > 0, "No dividend to withdraw");

    dividends[msg.sender] = 0;
    dest.transfer(amount);
  }


  // Non-public methods

  /**
   * @notice Internal function to handle token transfers between addresses
   * @param from The address to transfer tokens from
   * @param to The address to transfer tokens to
   * @param value The amount of tokens to transfer
   * @return success True if the transfer was successful
   */
  function _transfer(address from, address to, uint256 value) internal returns (bool) {
    require(balanceOf[from] >= value, "Insufficient balance");

    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);

    //update holder list
    _updateHolderList(from);
    _updateHolderList(to);

    emit Transfer(from, to, value);

    return true;
  }

  /**
   * @notice Internal function to maintain the list of token holders
   * @dev Adds account to holders list if they have tokens, removes if their balance is zero
   * @param account The address to update in the holders list
   */
  function _updateHolderList(address account) internal {
    uint256 currentIndex = holderIndex[account];

    if (balanceOf[account] == 0) {
      //remove from holder list if balance is zero
      if (currentIndex > 0) {
        //move last element to the position of element to delete
        uint256 lastIndex = holders.length;
        if (currentIndex != lastIndex) {
          address lastHolder = holders[lastIndex - 1];
          holders[currentIndex - 1] = lastHolder;
          holderIndex[lastHolder] = currentIndex;
        }
        holders.pop();
        holderIndex[account] = 0;
      }
    } else {
      //add to holder list if not already there
      if (currentIndex == 0) {
        holders.push(account);
        holderIndex[account] = holders.length;
      }
    }
  }

  /**
   * @notice Internal function to mint tokens to a specified account
   * @dev Increases the account's balance and total supply, updates holder list, and emits Transfer event
   * @param account The address to mint tokens to
   * @param amount The amount of tokens to mint
   */
  function _mint(address account, uint256 amount) internal {
    require(amount > 0, "Must send ETH to mint");

    balanceOf[account] = balanceOf[account].add(amount);
    totalSupply = totalSupply.add(amount);

    // Update holder list
    _updateHolderList(account);

    emit Transfer(address(0), account, amount);
  }
}