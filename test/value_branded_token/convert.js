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


const BN = require('bn.js');
const utils = require('../test_lib/utils.js');
const { AccountProvider } = require('../test_lib/utils.js');
const ValueBrandedTokenUtils = require('./utils.js');

contract('ValueBrandedToken::convert', async () => {
    contract('Returns', async (accounts) => {
        it('Returns correct conversions', async () => {
            const accountProvider = new AccountProvider(accounts);

            const valueBrandedToken = await ValueBrandedTokenUtils.createValueBrandedToken(accountProvider);

            const valueBrandedTokens0 = await valueBrandedToken.convert(new BN(0));

            assert.strictEqual(
                valueBrandedTokens0.cmp(
                    new BN(0),
                ),
                0,
            );

            const conversionRate = await valueBrandedToken.conversionRate();
            const conversionRateDecimals = await valueBrandedToken.conversionRateDecimals();
            const valueTokens1 = new BN(1);
            const valueBrandedTokens1 = await valueBrandedToken.convert(valueTokens1);

            assert.strictEqual(
                valueBrandedTokens1.cmp(
                    valueTokens1.mul(conversionRate).div(new BN(10).pow(conversionRateDecimals)),
                ),
                0,
            );
        });
    });
});