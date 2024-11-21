# Airdrop Distribution Smart Contract

## About

This Clarity smart contract implements an airdrop distribution system for tokens on the Stacks blockchain. It allows for the management of eligible recipients, token claiming, and reclaiming of unclaimed tokens after a specified period.

## Features

- Token airdrop distribution to eligible recipients
- Admin functions for managing the airdrop process
- Configurable airdrop amount per recipient
- Ability to reclaim unclaimed tokens after a set period
- Event logging system for tracking important contract actions
- Read-only functions for querying contract state

## Usage

### Admin Functions

1. **set-airdrop-active-status (new-active-status: bool)**
   - Activates or deactivates the airdrop.
   - Resets the start block when activated.

2. **add-eligible-recipient (recipient-address: principal)**
   - Adds a single recipient to the eligible list.

3. **remove-eligible-recipient (recipient-address: principal)**
   - Removes a single recipient from the eligible list.

4. **bulk-add-eligible-recipients (recipient-addresses: (list 200 principal))**
   - Adds multiple recipients (up to 200) to the eligible list in one transaction.

5. **update-airdrop-amount (new-amount: uint)**
   - Updates the amount of tokens to be distributed per recipient.

6. **update-reclaim-period (new-period: uint)**
   - Updates the number of blocks after which unclaimed tokens can be reclaimed.

7. **reclaim-unclaimed-tokens**
   - Allows the contract owner to reclaim unclaimed tokens after the reclaim period has ended.

### User Functions

1. **claim-airdrop-tokens**
   - Allows eligible recipients to claim their allocated tokens.

### Read-only Functions

1. **get-airdrop-active-status**
2. **is-recipient-eligible (recipient-address: principal)**
3. **has-recipient-claimed-airdrop (recipient-address: principal)**
4. **get-recipient-claimed-amount (recipient-address: principal)**
5. **get-total-tokens-distributed**
6. **get-airdrop-amount-per-recipient**
7. **get-reclaim-period**
8. **get-airdrop-start-block**
9. **get-event (event-id: uint)**

## Error Codes

- `ERROR-NOT-CONTRACT-OWNER (u100)`: Action restricted to contract owner
- `ERROR-AIRDROP-ALREADY-CLAIMED (u101)`: Recipient has already claimed tokens
- `ERROR-RECIPIENT-NOT-ELIGIBLE (u102)`: Recipient is not eligible for the airdrop
- `ERROR-INSUFFICIENT-TOKEN-BALANCE (u103)`: Insufficient tokens in the contract
- `ERROR-AIRDROP-NOT-ACTIVE (u104)`: Airdrop is not currently active
- `ERROR-INVALID-AMOUNT (u105)`: Invalid amount specified
- `ERROR-RECLAIM-PERIOD-NOT-ENDED (u106)`: Reclaim period has not ended yet

## Event Logging

The contract logs events for major actions:

- STATUS_CHANGE
- RECIPIENT_ADDED
- RECIPIENT_REMOVED
- BULK_RECIPIENTS_ADDED
- AMOUNT_UPDATED
- PERIOD_UPDATED
- TOKENS_CLAIMED
- TOKENS_RECLAIMED

Events can be retrieved using the `get-event` function.

## Important Considerations

1. Only the contract owner can perform administrative functions.
2. The airdrop must be active for recipients to claim tokens.
3. Recipients can only claim tokens once.
4. The contract owner should ensure sufficient token balance before starting the airdrop.
5. The reclaim period starts when the airdrop is activated.
6. Unclaimed tokens can only be reclaimed after the reclaim period has ended.

## Security

- The contract uses assert statements to enforce access control and validate conditions.
- Ensure proper access control when interacting with admin functions.
- Regularly monitor the contract's token balance and event logs.

## Contact

officialnwaneridaniel@gmail.com