pragma solidity ^0.4.24;


// Copyright 2018 OpenST Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import "./SafeMath.sol";
import "./EIP20TokenRequiredInterface.sol";


/**
 * @title Value Branded Token.
 *
 * @notice Supports staking value tokens for minting utility branded tokens
 *         where the conversion rate from value token to utility branded token
 *         is not 1:1.
 */
contract ValueBrandedToken is EIP20TokenRequiredInterface {

    /* Usings */

    using SafeMath for uint256;


    /* Events */

    event StakeRequested(
        uint256 _valueTokens,
        uint256 _valueBrandedTokens,
        address _beneficiary,
        address _staker,
        uint256 _gasPrice,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes _signature
    );

    event StakeRequestAccepted(
        address _staker,
        uint256 _valueTokens
    );

    event StakeRequestRejected(/*...*/);

    event GatewaySet(
        address _gateway
    );

    event TransferorAdded(
        address _transferor
    );


    /* Storage */

    EIP20TokenRequiredInterface public valueToken;
    address public gateway;
    uint256 private supply;

    mapping(address /* staker */ => uint256 /* value tokens */) public stakeRequests;
    mapping(address => uint256 /* value branded tokens */) private balances;
    mapping(address => mapping (address => uint256 /* value branded tokens */)) private allowed;
    mapping(address => bool) public canTransfer;


    /* Modifiers */

    modifier onlyTransferors {
        require(
            canTransfer[msg.sender],
            "Msg.sender is not a transferor."
        );
        _;
    }


    /* Constructor */

    /**
     * @dev Constructor requires:
     *          - valueToken address is not null.
     *
     * @param _valueToken Address for tokens staked to mint utility branded tokens.
     */
    constructor(
        EIP20TokenRequiredInterface _valueToken
        // TODO: conversion-rate-related parameters
    )
        public
    {
        require(
            _valueToken != address(0),
            "ValueToken is null."
        );

        valueToken = _valueToken;
    }


    /* External Functions */

    /**
     * @notice Transfers value tokens from msg.sender to itself,
     *         stores the amount of value branded tokens to mint if request is accepted,
     *         and emits information required to stake value branded tokens
     *         to mint utility branded tokens.
     *
     * @dev It is expected that this contract will have a sufficient allowance to
     *      transfer value tokens from the staker at the time this function is executed.
     *      this function is executed.
     *
     *      Function requires:
     *          - _valueTokens is not zero;
     *          - _beneficiary is not null;
     *          - _signature is not empty;
     *          - msg.sender does not have a stake request;
     *          - valueToken.transferFrom returns true.
     *
     * @param _valueTokens Amount of value tokens to stake.
     * @param _valueBrandedTokens Amount of value branded tokens to mint.
     * @param _beneficiary Beneficiary for minted utility branded tokens.
     * @param _gasPrice Gas price that msg.sender (staker) is ready to pay to complete
     *                  the stake and mint process.
     * @param _gasLimit Gas limit that staker is ready to pay to complete
     *                  the stake and mint process.
     * @param _nonce Nonce of staker address.
     * @param _signature Signature signed by staker.
     */
    function requestStake(
        uint256 _valueTokens,
        uint256 _valueBrandedTokens,
        address _beneficiary,
        uint256 _gasPrice,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes _signature
    )
        external
    {
        require(
            _valueTokens != 0,
            "ValueTokens is zero."
        );
        require(
            _beneficiary != address(0),
            "Beneficiary is null."
        );
        require(
            _signature.length != 0,
            "Signature is empty."
        );
        require(
            stakeRequests[msg.sender] == 0,
            "Staker has a stake request."
        );

        stakeRequests[msg.sender] = _valueTokens;

        emit StakeRequested(
            _valueTokens,
            _valueBrandedTokens,
            _beneficiary,
            msg.sender,
            _gasPrice,
            _gasLimit,
            _nonce,
            _signature
        );

        require(
            valueToken.transferFrom(msg.sender, address(this), _valueTokens),
            "ValueToken.transferFrom returned false."
        );
    }

    /**
     * @notice Mints value branded tokens for _staker, increases the supply,
     *         sets allowance for gateway to transfer the amount of minted
     *         value branded tokens from _staker, and deletes stake request.
     *
     * @dev Function requires:
     *          - gateway is set;
     *          - stake request is not 0.
     *
     * @param _staker Staker address.
     */
    function acceptStakeRequest(
        address _staker
    )
        external
    {
        require(
            gateway != address(0),
            "Gateway is not set."
        );

        require(
            stakeRequests[_staker] != 0,
            "Stake request is zero."
        );

        uint256 valueTokens = stakeRequests[_staker];
        delete stakeRequests[_staker];

        emit StakeRequestAccepted(_staker, valueTokens);

        uint256 valueBrandedTokens = convert(valueTokens);
        balances[_staker] = balances[_staker].add(valueBrandedTokens);
        supply = supply.add(valueBrandedTokens);

        emit Transfer(address(0), _staker, valueBrandedTokens);

        allowed[_staker][gateway] = valueBrandedTokens;

        emit Approval(_staker, gateway, valueBrandedTokens);
    }

    /**
     * @notice Transfers value tokens to staker and deletes stake request.
     *
     * @dev Function requires:
     *          - TBD.
     */
    function rejectStakeRequest(
    )
        external
        // TODO: returns
    {
        /*...*/
    }

    /**
     * @notice Transfers an amount of value tokens corresponding to the amount of redeemed value branded tokens to msg.sender.
     *
     * @dev Function requires:
     *          - TBD.
     */
    function redeem(
    )
        external
        // TODO: returns
    {
        /*...*/
    }

    /**
     * @notice Sets gateway.
     *
     * @dev Gateway cannot be set in the construction of this contract because
     *      the address of this contract is required to construct the Gateway.
     *
     *      Function requires:
     *          - gateway is not set.
     *
     * @param _gateway Gateway.
     */
    function setGateway(
        address _gateway
    )
        external
    {
        require(
            gateway == address(0),
            "Gateway is set."
        );

        gateway = _gateway;

        emit GatewaySet(gateway);

        addTransferor(_gateway);
    }

    /**
     * @notice Adds transferor.
     *
     * @dev Function requires:
     *          - _transferor is not null;
     *          - canTransfer[_transferor] is false;
     *
     * @param _transferor Transferor address to add.
     */
    function addTransferor(
        address _transferor
    )
        public
    {
        require(
            _transferor != address(0),
            "Transferor is null."
        );
        require(
            !canTransfer[_transferor],
            "Transferor can transfer."
        );

        canTransfer[_transferor] = true;

        emit TransferorAdded(_transferor);
    }

    /**
     * @notice Returns the supply.
     *
     * @return uint256 Supply.
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return supply;
    }

    /**
     * @notice Returns the balance of _owner.
     *
     * @param _owner Owner of tokens.
     *
     * @return uint256 Balance of _owner.
     */
    function balanceOf(
        address _owner
    )
        public
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    /**
     * @notice Returns the amount _spender is allowed to transfer from _owner.
     *
     * @param _owner Owner of tokens.
     * @param _spender Spender with allowance.
     *
     * @return uint256 Allowance of _spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Transfers _amount to _to.
     *
     * @dev Function requires:
     *          - msg.sender is a transferor
     *          - msg.sender has a balance at least equal to _amount.
     *
     * @param _to To address.
     * @param _amount Amount to transfer.
     *
     * @return bool Success.
     */
    function transfer(
        address _to,
        uint256 _amount
    )
        public
        onlyTransferors
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    /**
     * @notice Transfers _amount from _from to _to.
     *
     * @dev The intention is to limit tradeability whilst enabling transfers
     *      that support the token economy. Thus, the account executing the transfer
     *      is restricted and not the account from which tokens are transferred.
     *
     *      Function requires:
     *          - msg.sender is a transferor
     *          - _from has a balance at least equal to _amount;
     *          - msg.sender has an allowance at least equal to _amount.
     *
     * @param _from From address.
     * @param _to To address.
     * @param _amount Amount to transfer.
     *
     * @return bool Success.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        onlyTransferors
        returns (bool success)
    {
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);

        return true;
    }

    /**
     * @notice Sets an _amount _spender is approved
     *         to transfer.
     *
     * @dev Function requires:
     *          - TBD.
     */
    function approve(address, uint256) public returns (bool) {
        // TODO
    }


    /* Public Functions */

    /**
     * @notice Returns the converted amount of a given amount.
     *
     * @param _amount Amount to convert.
     *
     * @return uint256 Converted amount.
     */
    function convert(
        uint256 _amount
    )
        public
        pure
        returns (uint256)
    {
        // TODO: properly convert
        return _amount;
    }
}