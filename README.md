# Partial Refund Auction

A Solidity smart contract implementing a decentralized auction system with key features:

- Bidding system with minimum price enforcement.
- Each new bid must exceed the previous one by at least **5%**.
- Anti-sniping: late bids extend the auction time by 10 minutes.
- Partial refund system for bidders who placed multiple offers.
- 2% commission on refunded bids (retained by the contract owner).
- Only the owner can finalize the auction once the time is up.

---

## 📦 Contract Overview

### Contract Name: `Auction`

### Constructor

```solidity
constructor(uint256 _minPrice)

🔧 Functions

| Function          | Visibility         | Description                                                                                                      |
| ----------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `bid()`           | `external payable` | Places a bid. Must be higher than min price and 5% above current best.                                           |
| `winner()`        | `external view`    | Returns the current winning offer (last valid one).                                                              |
| `showOffers()`    | `external view`    | Returns all offers submitted.                                                                                    |
| `finishAuction()` | `external`         | Finalizes the auction and refunds all non-winning bidders (minus 2%). Only callable by owner after auction ends. |
| `partialRefund()` | `external`         | Allows users with multiple offers to request a partial refund of previous offers.                                |
| `receive()`       | `external payable` | Reverts any direct ETH transfers. Only `bid()` is allowed.                                                       |

⚙️ Internal Functions

| Function                       | Visibility | Description                                                         |
| ------------------------------ | ---------- | ------------------------------------------------------------------- |
| `handleOffer(Offer memory)`    | `private`  | Registers a new offer.                                              |
| `handleFinishTime()`           | `private`  | Extends auction time by 10 minutes if a bid is placed near the end. |
| `handleRefound(uint256 index)` | `private`  | Transfers partial refund and updates internal state.                |

🔒 Modifiers

| Modifier                     | Description                                                     |
| ---------------------------- | --------------------------------------------------------------- |
| `isActive`                   | Ensures auction hasn't ended.                                   |
| `isOwner`                    | Restricts function to contract owner.                           |
| `onlyAfterEnd`               | Restricts function to be callable only after auction has ended. |
| `hasAnyOffer`                | Requires that at least one offer has been made.                 |
| `meetsInitialPrice(uint256)` | Validates that bid meets minimum price.                         |
| `meetsBetterAmount(uint256)` | Validates that bid is at least 5% higher than the current best. |
| `hasDeposit`                 | Requires the sender to have deposited funds.                    |
| `hasMultipleOffers`          | Requires the sender to have made more than one offer.           |

📄 Events
| Event                           | Description                                      |
| ------------------------------- | ------------------------------------------------ |
| `NewOffer(Offer indexed offer)` | Emitted when a new offer is successfully placed. |
| `FinishAuction(address winner)` | Emitted when the auction is finalized.           |


🗃️ State Variables

| Variable         | Type                          | Description                               |
| ---------------- | ----------------------------- | ----------------------------------------- |
| `offers`         | `Offer[]`                     | Array of all submitted offers.            |
| `deposits`       | `mapping(address => uint256)` | Tracks total ETH deposited per bidder.    |
| `amountOfOffers` | `mapping(address => uint256)` | Tracks the number of offers per address.  |
| `owner`          | `address`                     | Contract deployer and auction manager.    |
| `minPrice`       | `uint256`                     | Minimum price required to bid.            |
| `startTime`      | `uint256`                     | Timestamp when the auction started.       |
| `finishTime`     | `uint256`                     | Timestamp when the auction is set to end. |

📌 Notes
* All ETH sent directly to the contract is rejected — bids must go through bid().

* The auction is extended by 10 minutes if a bid comes in the last 10 minutes.

* Only the owner can finalize the auction.

* Losing bidders receive 98% of their bid as refund; 2% is retained as commission.

* Partial refunds are only allowed for users with more than one offer.
