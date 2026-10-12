# STUDENT-QUESTIONS.md — Discussion questions (submit with your repo)

Answer directly under each question. 150–300 words each — **reasoning over length**.

---

## A. Permission design

**A1.** The vault holds `MINTER_ROLE`, so it can `burn` any user's balance. Explain why that is a risk, then write out how you would change `Vault` and `SimpleStablecoin` to remove it.

> Your answer:

MINTER_ROLE allows an address to burn tokens from any account, without that account's approval. This gives minters more power than they need. The current Vault only burns tokens belonging to the person calling redeem, and it cannot be upgraded. That limits what this particular Vault can do. Other minters, including the admin, still have permission to destroy someone else's balance.

A safer design would keep minting behind MINTER_ROLE but replace burn(address,uint256) with burnFrom(address,uint256). Before redeeming, the user would approve the Vault to spend a chosen amount of sUSD. Vault.redeem would call stable.burnFrom(msg.sender,amount). Here, msg.sender in Vault is the user, while the caller seen by SimpleStablecoin is Vault. The token would check and spend allowance(user,Vault), then burn the user's tokens. Calling burn(amount) from Vault instead would burn Vault's own balance.

The burn and USDC payment should stay in one transaction. If approval, balance, or reserves are insufficient, everything should revert. Tests should also check that having mint permission alone does not permit an unapproved burn.

**A2.** In this contract `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` all go to the same address. How would you split them in production, and who holds each?

> Your answer:

Giving all three roles to one wallet means a stolen key can control the whole coin. The attacker could add a new minter, create tokens, and pause normal users. Splitting the roles would reduce how much damage one stolen key can cause.

DEFAULT_ADMIN_ROLE should belong to a governance multisig with a timelock. Changes such as adding a minter should be announced before they take effect, so users have time to see the change. MINTER_ROLE should belong to reviewed contracts that require collateral before issuing tokens, such as Vault. The deployer's mint permission should be removed after setup. Otherwise, the deployer could still create unbacked tokens even if Vault works correctly. Supply caps and alerts could help detect unusual minting.

PAUSER_ROLE should belong to a separate emergency multisig. It needs to act quickly, so pausing should not wait for the normal governance delay. There should also be a clear process for unpausing. The signers must be independent: several keys held by the same person still leave one point of failure.

---

## B. Pausing and redemption

**B1.** `_update` is the single entry point for every balance change, so `pause()` freezes transfers, minting and redemption together. If you wanted "pause transfers but **allow redemption**", how would you change it? Give the approach — full code not required.

> Your answer:

The current pause check sits in _update, which handles transfers, minting, and burning. Redeeming needs a burn, so the same check also stops users from getting their collateral back.

To pause transfers while allowing redemption, the check could depend on from and to. If both addresses are nonzero, the operation is a transfer and should fail while transfers are paused. Both transfer and transferFrom pass through this check. Minting has a zero from address, so it could have its own pause flag. Burning has a zero to address and could remain available for redemption.

Allowing a burn during a pause should not give minters permission to burn anyone's balance. The burnFrom approval check described in A1 should still apply. Vault would check its reserves, burn the approved amount, and return USDC in one transaction. A failed payment would undo the burn. Tests should cover paused transfers and minting separately, then show that approved redemption still works when enough collateral is available.

**B2.** In 2008, when a money-market fund "broke the buck", redemptions were frozen for days. In 2023 USDC depegged to $0.87 after a reserve bank failed, but redemptions were **not** shut. Compare the two responses — what does closing the redemption channel, or leaving it open, do to a stablecoin?

> Your answer:

When redemption closes, holders cannot exchange their tokens for the promised reserve assets. A freeze may stop withdrawals while the issuer works out how much money is available. It can also make people less willing to hold the token, because they do not know when they will be paid or how much they will receive.

An open redemption channel gives buyers a reason to buy below one dollar. If someone buys a token for $0.87 and can redeem it for $1, that trade can push the market price back toward the peg. This depends on the issuer actually being able to pay. During the USDC episode, the promise of dollar redemption after banking settlement resumed helped restore confidence. Keeping that promise did not mean bank transfers worked continuously over the weekend.

Neither choice fixes missing reserves. Leaving redemption open with insufficient assets can favor early withdrawals. A response should explain whether the problem is a temporary payment delay or a real loss, and state when holders can expect payment.

---

## C. Depeg analysis

**C1.** Under what conditions does this coin depeg? Distinguish at least two classes of cause, and say how each one shows up in the invariant `totalCollateral() >= totalSupply()`.

> Your answer:

One possible cause is unbacked minting. An attacker with MINTER_ROLE can create sUSD without depositing USDC. Supply increases while the collateral balance stays the same. If the two were equal before the attack, totalCollateral() >= totalSupply() now fails. Ex3 shows this shortage. It does not show an actual market price, because the local lab has no exchange where sUSD is traded.

Another cause is blocked redemption. A pause stops the burn needed to redeem. The reserves may still cover every token, so the invariant passes, but holders cannot use them. Transfer restrictions on the collateral could have a similar effect. Without a working redemption channel, buying discounted sUSD may not lead to a dollar payment, so the market price can fall.

The invariant also ignores the collateral's dollar price. If USDC itself depegs, its balance does not change, and the check can pass even when the reserves are worth too little. Direct USDC donations create the opposite case: collateral exceeds supply. That surplus is why the backing check uses >= rather than equality.

**C2.** Suppose an attacker bribes their way to `MINTER_ROLE`, mints 1,000,000 sUSD out of nothing and redeems it all. Describe the flow of funds, and name the step that could have stopped them.

> Your answer:

The attacker calls mint(attacker,1_000_000e6) after getting MINTER_ROLE. Their sUSD balance and the total supply rise by one million, but Vault receives no USDC. The attacker then calls redeem. In this version, no sUSD approval is needed because Vault already has permission to burn the caller's tokens.

Redeeming the whole amount only works if Vault holds at least one million USDC. Vault checks its reserves before burning or paying. If the requested amount is larger, InsufficientCollateral reverts the transaction. The recorded lab reserves are only 1,000 USDC, so a one-million redemption would fail. The attacker could instead redeem 1,000 sUSD and take all those reserves. Honest holders would then have tokens with no remaining backing, while the attacker would still hold most of the unbacked tokens.

The step that should stop this is the role grant. Mint permission should go only to contracts that enforce collateral deposits. A multisig and timelock can make a bad role change harder. The reserve check alone cannot tell honest tokens apart from tokens minted by the attacker.

---

## D. Toward RWA

**D1.** Right now the collateral is `MockUSDC` and `totalCollateral()` just reads an on-chain balance — simple and reliable. If the collateral were **US Treasuries**, could this invariant still be written that way? What new problems appear?

> Your answer:

For US Treasuries, reading one token balance would not be enough. A Treasury token is a claim on securities held elsewhere. The system needs proof that a custodian holds those securities and that token holders have enforceable rights to them. It also needs to know whether the assets have been pledged to another lender.

The backing check should compare the dollar value of available reserves with the stablecoin supply, using matching units. That value should include current prices and accrued interest, with a discount for risk. Face value alone is not enough: a bond may sell below face value when interest rates rise. Reports need dates and a maximum allowed age, because an old valuation can hide a loss.

Enough assets do not always mean enough cash for immediate redemption. Treasuries may need to be sold and settled first. The issuer would need a cash buffer and stated payment times. Custody agreements, reserve reports, and checks against the custodian's records would support the on-chain numbers. Solidity cannot confirm physical custody or settle competing legal claims by itself.

**D2.** If the collateral were **a building**, how would you put it inside this vault? Which off-chain roles or legal structures would you have to introduce?

> Your answer:

A building cannot be transferred into a smart contract. An SPV or trust would own it, and the token deposited in Vault would represent a legal claim. The documents would need to say what that claim means: shares in the owner, secured debt, or a right to rental income. These give holders different rights if something goes wrong.

A property manager would collect rent and handle repairs, insurance, and tenants. An administrator or trustee would manage the ownership structure. Appraisers would estimate the building's value, and auditors would check its ownership and debts. Lawyers would define the token holders' rights and who gets paid first if the property is sold or the owner becomes insolvent.

Vault would use a cautious net value after mortgages, taxes, and costs. An appraisal does not guarantee that a buyer will pay that amount. Selling a building also takes time. The system would need cash reserves and a withdrawal queue, with clear rules for payment delays and for sharing losses if sale proceeds are too low.

---

## E. Tests (Tier 1 required — this is Ex4)

Turn the red tests green in `test/exercises/01_LoopTasks.t.sol` to cover the scenarios below, and write your test function names here:

| Scenario | Your test function name |
|---|---|
| Minting by a non-minter reverts | `test_Ex4_Mint_RevertsForNonMinter` |
| Transfers revert while paused | `test_Ex4_Pause_BlocksTransfers` |
| **Redemption** reverts while paused | `test_Ex4_Pause_BlocksRedeem` |
| An attacker cannot burn someone else's balance | `test_Ex4_AttackerCannotBurnOthersBalance` |
| ...but the vault holding `MINTER_ROLE` can | `test_Ex4_VaultHoldsTheKey_CanBurnAnyonesBalance` |

That last pair is meant to be read together: the guard is written correctly, but the key was handed to the vault. Keep it in mind when you answer A1.

Now write one more scenario you consider **most likely to be attacked**, and say why you picked it:

> Your answer:

Test whether a stolen admin key can grant MINTER_ROLE to an attacker, who then mints unbacked sUSD and redeems up to the available USDC balance. This is a useful attack case because the current admin can grant that role directly, and the reserve check cannot identify how the redeemed tokens were minted.
