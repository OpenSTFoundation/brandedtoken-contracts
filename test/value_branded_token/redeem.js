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
const { Event } = require('../test_lib/event_decoder');
const { AccountProvider } = require('../test_lib/utils.js');
const ValueBrandedTokenUtils = require('./utils.js');

const EIP20TokenMockPassFail = artifacts.require('EIP20TokenMockPassFail');
const ValueBrandedToken = artifacts.require('ValueBrandedToken');

contract('ValueBrandedToken::redeem', async () => {
    contract('Negative Tests', async (accounts) => {
        const accountProvider = new AccountProvider(accounts);
        const worker = accountProvider.get();

        it('Reverts if balance is less than redeem amount', async () => {
            const {
                valueBrandedToken,
                valueTokens,
                staker,
            } = await ValueBrandedTokenUtils.createValueBrandedTokenAndStakeRequest(accountProvider, worker);

            const valueBrandedTokens = 1;

            await utils.expectRevert(
                valueBrandedToken.redeem(
                    valueBrandedTokens,
                    { from: staker },
                ),
                'Should revert as staker has a balance less than redeem amount.',
            );
        });

        it('Reverts if valueToken.transfer returns false', async () => {
            const valueToken = await EIP20TokenMockPassFail.new();
            const conversionRate = 35;
            const conversionRateDecimals = 1;

            const worker = accountProvider.get();
            const organizationMock = await ValueBrandedTokenUtils.organizationMock();
            await organizationMock.setWorker(worker);

            const valueBrandedToken = await ValueBrandedToken.new(
                valueToken.address,
                conversionRate,
                conversionRateDecimals,
                organizationMock.address,
            );

            const valueTokens = 1;
            const valueBrandedTokens = await valueBrandedToken.convert(valueTokens);
            const beneficiary = accountProvider.get();
            const gasPrice = 0;
            const gasLimit = 0;
            const nonce = 0;
            const signature = '0x00';

            const staker = accountProvider.get();
            const gateway = accountProvider.get();

            await valueBrandedToken.requestStake(
                valueTokens,
                valueBrandedTokens,
                beneficiary,
                gasPrice,
                gasLimit,
                nonce,
                signature,
                { from: staker },
            );

            await valueBrandedToken.setGateway(
                gateway,
            );

            await valueBrandedToken.acceptStakeRequest(
                staker,
                { from: worker },
            );

            await utils.expectRevert(
                valueBrandedToken.redeem(
                    valueBrandedTokens,
                    { from: staker },
                ),
                'Should revert as valueToken.transfer returned false.',
                'ValueToken.transfer returned false.',
            );
        });
    });

    contract('Events', async (accounts) => {
        const accountProvider = new AccountProvider(accounts);

        it('Emits Transfer event', async () => {
            const worker = accountProvider.get();
            const {
                valueBrandedToken,
                valueTokens,
                staker,
            } = await ValueBrandedTokenUtils.createValueBrandedTokenAndStakeRequest(accountProvider, worker);

            await valueBrandedToken.acceptStakeRequest(
                staker,
                { from: worker },
            );

            const valueBrandedTokens = await valueBrandedToken.convert(valueTokens);

            const transactionResponse = await valueBrandedToken.redeem(
                valueBrandedTokens,
                { from: staker },
            );

            const events = Event.decodeTransactionResponse(
                transactionResponse,
            );

            assert.strictEqual(
                events.length,
                1,
                'Only Transfer event should be emitted.',
            );

            Event.assertEqual(events[0], {
                name: 'Transfer',
                args: {
                    _from: staker,
                    _to: utils.NULL_ADDRESS,
                    _value: valueBrandedTokens,
                },
            });
        });
    });

    contract('Storage', async (accounts) => {
        const accountProvider = new AccountProvider(accounts);

        it('Successfully reduces supply and redeemer balance and calls valueToken.transfer', async () => {
            const worker = accountProvider.get();
            const valueBrandedToken = await ValueBrandedTokenUtils.createValueBrandedToken(worker);

            const valueTokens = 100;
            const valueBrandedTokens = await valueBrandedToken.convert(valueTokens);
            const beneficiary = accountProvider.get();
            const gasPrice = 0;
            const gasLimit = 0;
            const nonce = 0;
            const signature = '0x00';

            const staker = accountProvider.get();
            const gateway = accountProvider.get();

            await valueBrandedToken.requestStake(
                valueTokens,
                valueBrandedTokens,
                beneficiary,
                gasPrice,
                gasLimit,
                nonce,
                signature,
                { from: staker },
            );

            await valueBrandedToken.setGateway(
                gateway,
            );

            await valueBrandedToken.acceptStakeRequest(
                staker,
                { from: worker },
            );

            const totalSupplyBefore = await valueBrandedToken.totalSupply();
            const balanceBefore = await valueBrandedToken.balanceOf(staker);
            const conversionRate = await valueBrandedToken.conversionRate();
            const conversionRateDecimals = await valueBrandedToken.conversionRateDecimals();

            // Redeem amount that evaluates to an integer value token amount
            const redeemAmountWhole = conversionRate;

            // Redeem amount that evaluates (absent precision limits of Solidity) to a non-integer value token amount
            const redeemAmountPartial = redeemAmountWhole.addn(1);

            assert.strictEqual(
                totalSupplyBefore.cmp(
                    valueBrandedTokens,
                ),
                0,
            );

            assert.strictEqual(
                balanceBefore.cmp(
                    valueBrandedTokens,
                ),
                0,
            );

            // Redemption amounts are not equal
            assert.strictEqual(
                redeemAmountWhole.cmp(
                    redeemAmountPartial,
                ),
                -1,
            );

            const resultAmount1 = await valueBrandedToken.redeem.call(
                1,
                { from: staker },
            );

            const resultAmountWhole = await valueBrandedToken.redeem.call(
                redeemAmountWhole,
                { from: staker },
            );

            const resultAmountPartial = await valueBrandedToken.redeem.call(
                redeemAmountPartial,
                { from: staker },
            );

            // Redemption can result in receiving 0 value tokens
            assert.strictEqual(
                resultAmount1.cmp(
                    new BN(0),
                ),
                0,
            );

            assert.strictEqual(
                resultAmountWhole.cmp(
                    redeemAmountWhole.mul(new BN(10).pow(conversionRateDecimals)).div(conversionRate),
                ),
                0,
            );

            assert.strictEqual(
                resultAmountPartial.cmp(
                    redeemAmountPartial.mul(new BN(10).pow(conversionRateDecimals)).div(conversionRate),
                ),
                0,
            );

            // Different redemption amounts can receive the same amount of value tokens--redemption can result in loss
            assert.strictEqual(
                resultAmountWhole.cmp(
                    resultAmountPartial,
                ),
                0,
            );

            await valueBrandedToken.redeem(
                1,
                { from: staker },
            );

            await valueBrandedToken.redeem(
                redeemAmountWhole,
                { from: staker },
            );

            await valueBrandedToken.redeem(
                redeemAmountPartial,
                { from: staker },
            );

            const totalRedemption = redeemAmountWhole.add(redeemAmountPartial).addn(1);
            const totalSupplyAfter = await valueBrandedToken.totalSupply();
            const balanceAfter = await valueBrandedToken.balanceOf(staker);

            assert.strictEqual(
                totalSupplyAfter.cmp(
                    totalSupplyBefore.sub(totalRedemption),
                ),
                0,
            );

            assert.strictEqual(
                balanceAfter.cmp(
                    balanceBefore.sub(totalRedemption),
                ),
                0,
            );
        });
    });
});
