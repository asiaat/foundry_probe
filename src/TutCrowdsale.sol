// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SimulaToken.sol";
import "./RefundableVault.sol";

contract TutCrowdsale {
  
  // Track investor contributions
  uint256 public investorMinCap  = 2000000000000000;        // 0.002 ether
  uint256 public investorHardCap = 100000000000000000000;   // 100 ether
  mapping(address => uint256) public contributions;

  // The token being sold
  SimulaToken public token;

  // Address where funds are collected
  address payable public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Limit for total contributions
  uint256 public cap;

  uint256 public openingTime;
  uint256 public closingTime;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  bool public isFinalized = false;

  event Finalized();

  // refund vault used to hold funds while crowdsale is running
  RefundableVault public vault;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(
        uint256 _rate, 
        address payable _wallet, 
        SimulaToken _token, 
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _goal
    ) 
    public 
    {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_cap > 0);
        require(_openingTime >= block.timestamp);
        require(_closingTime >= _openingTime);
        require(_goal > 0);
        require(_goal <= _cap);

        rate    = _rate;
        wallet  = _wallet;
        token   = _token;
        cap     = _cap;
        goal    = _goal;
    }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

   /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileOpen {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > closingTime;
    }

   /**
    * @dev Returns the amount contributed so far by a sepecific user.
    * @param _beneficiary Address of contributor
    * @return User contribution so far
    */
    function getUserContribution(address _beneficiary)
        public view returns (uint256)
    {
        return contributions[_beneficiary];
    }

    /**
    * @dev Investors can claim refunds here if crowdsale is unsuccessful
    */
    function claimRefund(address payable investor) public  {
        require(isFinalized);
        require(!goalReached());

        // was vault.refund(msg.sender);
        vault.refund(investor);
    }

    /**
    * @dev Checks whether funding goal was reached.
    * @return Whether funding goal was reached
    */
    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

    /**
    * @dev vault finalization task, called when owner calls finalize()
    */
    function finalization() internal {
        if (goalReached()) {
        vault.close();
        } else {
        vault.enableRefunds();
        }

        
    }


  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  fallback () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // Validate quantum specific here?

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised += weiAmount;

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require((_weiAmount + weiRaised) <= cap);

    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution + _weiAmount;

    require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
    contributions[_beneficiary] = _newContribution;
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    //token.transfer(_beneficiary, _tokenAmount);
    token.mint(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount * rate;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}