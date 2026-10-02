# STUDENT-QUESTIONS.md — Discussion questions (submit with your repo)

Answer directly under each question. 150–300 words each — **reasoning over length**.

---

## A. Permission design

**A1.** The vault holds `MINTER_ROLE`, so it can `burn` any user's balance. Explain why that is a risk, then write out how you would change `Vault` and `SimpleStablecoin` to remove it.

> Your answer:

The risk is that `MINTER_ROLE` is stronger than the vault actually needs. In this implementation, `SimpleStablecoin.burn(from, amount)` is protected by `onlyRole(MINTER_ROLE)`, so the vault can burn tokens from any address, not only from the user who is redeeming. The current `Vault.redeem()` uses that power in a normal way: it burns `msg.sender`'s sUSD and sends them USDC. But if the vault is upgraded badly, called through a bug, or reused in another context, the same role lets it destroy balances that did not consent. That is a dangerous key-design problem, not a math problem.

I would split minting from burning. `SimpleStablecoin` should expose `mint(address to, uint256 amount)` for authorized minters, but redemption burning should either be `burn(uint256 amount)` from `msg.sender` or `burnFrom(address from, uint256 amount)` using ERC20 allowance. Then `Vault.redeem()` would require the user to approve the vault or call a stablecoin method that burns only the caller's own tokens. The vault could still mint when collateral arrives, but it would no longer have a general "burn anyone" power.

**A2.** In this contract `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` all go to the same address. How would you split them in production, and who holds each?

> Your answer:

In production I would not give all three roles to one hot wallet. `DEFAULT_ADMIN_ROLE` is the most dangerous role because it can grant and revoke the other roles, so it should be held by a multisig or timelock controlled by governance, not by a single deployer account. Changes to minting or pausing authority should be slow enough for users and monitors to see them before they take effect.

`MINTER_ROLE` should be granted only to contracts that are part of the mint-redeem path, such as the vault or a Peg Stability Module. Human operators should not mint directly in normal operation. If emergency minting is ever needed, it should go through a separate governed process with public limits.

`PAUSER_ROLE` should be held by a security council or operations multisig that can react quickly to an exploit. This role needs faster response than admin governance, but it should still be multi-person and auditable. I would also make pausing limited: pause risky actions first, preserve redemption if reserves are sound, and require a clear unpause process.

---

## B. Pausing and redemption

**B1.** `_update` is the single entry point for every balance change, so `pause()` freezes transfers, minting and redemption together. If you wanted "pause transfers but **allow redemption**", how would you change it? Give the approach — full code not required.

> Your answer:

Right now pausing is implemented through `_update`, which is the OpenZeppelin ERC20 hook used for transfers, minting, and burning. That is simple, but it makes pause too broad: when paused, users cannot transfer, new coins cannot be minted, and redemptions cannot burn sUSD. If the goal is "pause transfers but allow redemption", the pause check should not live in the single shared `_update` path.

I would separate the stablecoin's external actions by intent. Normal user transfers should check `whenNotPaused`, while redemption burning should remain available through a dedicated method that is callable only by the vault and only as part of `Vault.redeem()`. Minting could be separately paused or rate-limited, depending on the emergency design. Another clean approach is to use separate flags, for example `transfersPaused`, `mintingPaused`, and `redemptionsPaused`, instead of one global pause.

The main design point is that redemption is the stabilizing exit channel. If collateral exists and the system is not insolvent, users should still be able to burn sUSD and receive collateral even while secondary transfers are stopped.

**B2.** In 2008, when a money-market fund "broke the buck", redemptions were frozen for days. In 2023 USDC depegged to $0.87 after a reserve bank failed, but redemptions were **not** shut. Compare the two responses — what does closing the redemption channel, or leaving it open, do to a stablecoin?

> Your answer:

Closing redemption and leaving redemption open send opposite signals to the market. If redemptions are frozen, holders can no longer convert the stablecoin back into the reserve asset at par. Even if the issuer eventually has enough assets, users face uncertainty about timing and access. That uncertainty usually pushes the token price below $1 because buyers demand a discount for lockup risk, legal risk, and information risk. A redemption freeze can slow a bank-run mechanically, but it also damages the claim that the coin is cash-like.

Leaving redemption open is riskier in the short term because reserves may leave quickly, but it supports confidence if the issuer is actually solvent. In the USDC example, the market saw a depeg when part of the reserve was exposed to a failed bank, but the redemption mechanism was not permanently closed. Once the market believed redemptions would continue and reserves were recoverable, arbitrage could pull the price back toward $1.

For a stablecoin, redemption is not just a feature. It is the main price defense. Freezing it should be an extreme last resort.

---

## C. Depeg analysis

**C1.** Under what conditions does this coin depeg? Distinguish at least two classes of cause, and say how each one shows up in the invariant `totalCollateral() >= totalSupply()`.

> Your answer:

This coin can depeg for at least two different classes of reasons. The first is an accounting or permission failure that creates more sUSD than collateral. Ex3 demonstrates this directly: if an attacker gets `MINTER_ROLE`, they can mint sUSD without depositing USDC. Then `stable.totalSupply()` rises while `vault.totalCollateral()` stays the same. The invariant `totalCollateral() >= totalSupply()` breaks immediately, and the coin is under-collateralized on-chain.

The second class is a redemption or liquidity failure. The invariant may still look true, but users may not be able to redeem. For example, if pausing freezes burn/redemption, or if the collateral token cannot be transferred, the system may be fully backed in accounting terms while the market price falls because holders cannot exit at $1. In that case the invariant is necessary but not sufficient.

There is also off-chain collateral risk in real systems. If the reserve is a bank deposit, Treasury bill, or building, the on-chain balance may not represent immediately available value. The invariant only captures what the contract can measure.

**C2.** Suppose an attacker bribes their way to `MINTER_ROLE`, mints 1,000,000 sUSD out of nothing and redeems it all. Describe the flow of funds, and name the step that could have stopped them.

> Your answer:

If an attacker obtains `MINTER_ROLE`, they can call `SimpleStablecoin.mint(attacker, 1_000_000e6)` without sending collateral to the vault. Their sUSD balance increases, and total supply increases, but `Vault.totalCollateral()` does not change. At that point the system has already become under-collateralized.

The next step is redemption. If the vault holds real USDC from honest users, the attacker can approve or otherwise use the redemption path to burn their fake sUSD and withdraw USDC. In this simplified vault, `redeem(amount)` burns the caller's sUSD and transfers the same amount of USDC from the vault. The attacker is therefore converting unbacked tokens into backed collateral, draining reserves that should belong to legitimate holders.

The step that should have stopped them is role control before minting. `MINTER_ROLE` should only be granted to audited minting contracts that enforce collateral checks. Admin role changes should require multisig or timelock approval, and the stablecoin should ideally have separate minting caps and monitoring so an abnormal mint cannot silently happen.

---

## D. Toward RWA

**D1.** Right now the collateral is `MockUSDC` and `totalCollateral()` just reads an on-chain balance — simple and reliable. If the collateral were **US Treasuries**, could this invariant still be written that way? What new problems appear?

> Your answer:

If the collateral were US Treasuries, `totalCollateral()` could not simply read an ERC20 balance and be done. Treasuries exist off-chain or through custodians, brokers, tokenized wrappers, and settlement systems. The contract would need some trusted source to report how many Treasuries are held, their current value, maturity, haircut, and whether they are encumbered. That introduces oracle and custodian risk.

The invariant also becomes more complex because Treasuries are not identical to USDC. Their market value moves with interest rates, they may settle on T+1, and they may not be liquid at par during stress. A real invariant would need to measure collateral value after haircuts, not just face value. For example, it might require `riskAdjustedCollateralValue >= stableSupply`, where risk-adjusted value comes from an oracle and internal risk model.

The hardest new problem is trust. The smart contract can verify token balances, but it cannot independently verify that a custodian truly holds specific Treasury bills or that they can be sold fast enough during redemptions. Legal claims, audits, and reporting become part of the system.

**D2.** If the collateral were **a building**, how would you put it inside this vault? Which off-chain roles or legal structures would you have to introduce?

> Your answer:

A building cannot be put into a vault the same way USDC can. The chain cannot hold the physical asset directly, so the vault would need a legal wrapper. Usually that means a special purpose vehicle or trust owns the building, and the on-chain token represents a claim on that entity or its cash flows. The smart contract would track tokenized claims, while the real control of the building depends on legal documents and off-chain enforcement.

Several roles become necessary. A custodian or trustee must hold title or manage the SPV. A property manager handles rent, maintenance, insurance, and tenants. An appraiser or valuation oracle reports market value. A legal administrator handles liens, taxes, and sale rights. Auditors verify that the property exists, is owned by the right entity, and is not pledged elsewhere.

The invariant would also change. `totalCollateral()` would not be a simple balance; it would be an appraised and haircut-adjusted value, updated periodically. Redemption may not be instant because buildings are illiquid. A real design would need withdrawal queues, liquidity buffers, and clear rules for what token holders can claim if the building must be sold.

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

The most likely attack target is permission compromise, especially `MINTER_ROLE` or `DEFAULT_ADMIN_ROLE`. The reason is that a stablecoin's core promise depends on controlled issuance. If an attacker can mint without depositing collateral, every other invariant becomes secondary: they can create unbacked sUSD, sell it into the market, or redeem it against honest users' collateral. This is also operationally realistic because admin keys, multisigs, deployment scripts, and role-grant transactions are common places for mistakes. A code bug in deposit math might be narrow, but a role mistake affects the whole supply.
