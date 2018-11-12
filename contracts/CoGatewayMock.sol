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

import "./CoGatewayUtilityTokenInterface.sol";
import "./UtilityTokenInterface.sol";


/**
 *  @title CoGatewayMock contract.
 *
 *  @notice It contains utility token address.
 */
contract CoGatewayMock is CoGatewayUtilityTokenInterface{


    /* Storage */

    /** Address of utilityToken */
    address public utilityToken;


    /* Special functions */

    constructor(address _utilityToken) public{

        utilityToken = _utilityToken;

    }


    /* External methods */

    /**
     * @notice Get the utility token address.
     *
     * @return address of utility token.
     */
    function utilityToken() external view returns (address)
    {
        return utilityToken;
    }

}
