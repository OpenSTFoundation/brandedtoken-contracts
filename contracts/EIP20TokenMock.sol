/* solhint-disable-next-line compiler-fixed */
pragma solidity ^0.4.23;

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

import "./EIP20Token.sol";


/**
 * @title EIP20TokenMock contract.
 *
 * @notice It provides EIP20Token with mock functionality to facilitate testing
 *         payments.
 */
contract EIP20TokenMock is EIP20Token {

    /* Storage */

    uint256 public conversionRate;
    uint8 public conversionRateDecimals;


    /* Special functions */

    /**
     *  @dev Takes _conversionRate, _symbol, _name, _decimals.
     *
     *  @param _conversionRate ConversionRate.
     *  @param _symbol Symbol.
     *  @param _name Name.
     *  @param _decimals Decimals.
     */
    constructor(
        uint256 _conversionRate,
        uint8 _conversionRateDecimals,
        string _symbol,
        string _name,
        uint8 _decimals
    )
        /* solhint-disable-next-line visibility-modifier-order */
        EIP20Token(_symbol, _name, _decimals)
        public
    {
        conversionRate = _conversionRate;
        conversionRateDecimals = _conversionRateDecimals;
    }


    /* Public functions */

    /**
     * @notice Returns 0 as mock total supply.
     *
     * @return Returns 0.
     */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return 0;
    }

    /**
     * @notice Takes _owner, _value; sets balance of _owner to _value.
     *
     * @param _owner Owner.
     * @param _value Value.
     *
     * @return True if balances of the _owner is set.
     */
    function setBalance(
        address _owner,
        uint256 _value
    )
        public
        returns (bool)
    {
        balances[_owner] = _value;
        return true;
    }

    /**
     * @notice Takes _conversionRate; sets conversionRate to _conversionRate.
     *
     * @param _conversionRate ConversionRate.
     *
     * @return True if conversionRate is set.
     */
    function setConverionRate(
        uint256 _conversionRate
    )
        public
        returns (bool)
    {
        conversionRate = _conversionRate;
        return true;
    }
}