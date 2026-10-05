# STUDENT-QUESTIONS.md — Discussion questions (submit with your repo)

Answer directly under each question. 150–300 words each — **reasoning over length**.

---

## A. Permission design

**A1.** The vault holds `MINTER_ROLE`, so it can `burn` any user's balance. Explain why that is a risk, then write out how you would change `Vault` and `SimpleStablecoin` to remove it.

> Your answer:

The risk is excessive authority: MINTER_ROLE permits burning any address without explicit individual consent. Vault.redeem currently burns only its caller's tokens, and this deployed Vault has no upgrade mechanism. Nevertheless, privileged burning expands the trust boundary: every minter, including the administrator, can destroy unrelated balances.

I would retain role protected minting but remove burn(address,uint256). SimpleStablecoin would expose burnFrom(address,uint256), consuming the caller's allowance before burning. A redeeming user first approves the Vault for the intended sUSD amount. Vault.redeem then calls stable.burnFrom(msg.sender,amount), where msg.sender inside Vault identifies that user. SimpleStablecoin checks allowance(user,Vault) against the requested amount; the user's sufficient balance is verified independently during burning. Calling burn(amount) directly from Vault would instead burn Vault's own tokens.

Burning and returning USDC remain atomic: insufficient allowance, balance, or reserves causes the entire transaction to revert. Tests should prove authorized redemption succeeds while unauthorized burning fails, including attempts by addresses that still possess minting authority.

**A2.** In this contract `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` all go to the same address. How would you split them in production, and who holds each?

> Your answer:

In production I would separate authority because one compromised wallet currently controls issuance, role assignment, and emergency response. DEFAULT_ADMIN_ROLE should belong to a governance multisig operating through a timelock. Granting new minters or replacing administrators should have a public delay, allowing monitors and users to react before authority changes.

MINTER_ROLE should belong only to reviewed contracts whose issuance requires collateral, such as Vault. The deployer should relinquish its minting role after configuration; otherwise restricting Vault alone leaves another unbacked issuance path. Caps and alerts provide additional protection against unexpected issuance.

PAUSER_ROLE should belong to a separate security council multisig, able to stop dangerous operations promptly without waiting through the governance delay. Its powers should be limited to emergency controls, with a documented unpause process.

These arrangements require independent signers and secure key handling. A multisig with several keys controlled by one person reproduces the original failure point under different addresses.

---

## B. Pausing and redemption

**B1.** `_update` is the single entry point for every balance change, so `pause()` freezes transfers, minting and redemption together. If you wanted "pause transfers but **allow redemption**", how would you change it? Give the approach — full code not required.

> Your answer:

The current whenNotPaused modifier on _update blocks every balance change, including the burn required by Vault.redeem. I would replace that unconditional check with checks based on the operation's endpoints. When both from and to are nonzero, the operation is a transfer and must revert while transfers are paused. This covers both transfer and transferFrom because both reach _update.

Minting has a zero from address and can use a separate minting pause flag. Burning has a zero to address and remains available for authorized redemption. Burn permission must still require user consent, for example the allowance checked by burnFrom; allowing burns during a pause must not restore arbitrary confiscation powers.

Vault.redeem would continue checking available collateral, burning the user's approved amount, and returning collateral atomically. A separate redemption flag could address an actual reserve or collateral transfer failure. Tests should distinguish paused transfers, paused issuance, and successful redemption against available reserves.

**B2.** In 2008, when a money-market fund "broke the buck", redemptions were frozen for days. In 2023 USDC depegged to $0.87 after a reserve bank failed, but redemptions were **not** shut. Compare the two responses — what does closing the redemption channel, or leaving it open, do to a stablecoin?

> Your answer:

Freezing redemption removes the holder's ability to exchange a claim for reserve assets at par. Buyers then discount uncertainty about asset value, payout timing, and access. A freeze can conserve liquidity and limit withdrawals, but it also disables redemption arbitrage: purchasing discounted tokens no longer guarantees a prompt profitable exit. Liquidity protection therefore comes at a cost to confidence.

Keeping a redemption commitment supports that arbitrage when reserves are accessible. Holders can convert tokens into dollars, and traders buying below par can redeem rather than depend solely on finding another buyer. In the USDC episode, support for par conversion once banking settlement resumed helped restore confidence; a redemption commitment does not imply uninterrupted weekend bank settlement.

Neither response creates missing assets. An insolvent issuer cannot sustainably promise full repayment merely by keeping withdrawals open. Emergency policy should distinguish temporary settlement constraints from losses, disclose reserve conditions, and explain redemption timing.

---

## C. Depeg analysis

**C1.** Under what conditions does this coin depeg? Distinguish at least two classes of cause, and say how each one shows up in the invariant `totalCollateral() >= totalSupply()`.

> Your answer:

The first class is a backing failure. If compromised MINTER_ROLE authority creates sUSD without a deposit, totalSupply rises while totalCollateral remains unchanged. Starting from equal backing, the inequality totalCollateral >= totalSupply becomes false immediately. Ex3 demonstrates this deficit, although the local experiment does not measure a traded market price.

The second class is an access or liquidity failure. Pausing prevents burning, so holders cannot redeem even when collateral balances cover supply. A collateral token transfer restriction can produce the same result. The inequality remains true, but redemption arbitrage cannot operate, allowing market prices to fall below par.

Collateral valuation creates another limitation. If the collateral itself loses dollar value, its token balance does not change, so the raw inequality can pass despite inadequate backing. Real reserves need valuation and liquidity checks.

Direct collateral donations can also make collateral exceed supply harmlessly. Equality describes the loop; the inequality accommodates surplus backing.

**C2.** Suppose an attacker bribes their way to `MINTER_ROLE`, mints 1,000,000 sUSD out of nothing and redeems it all. Describe the flow of funds, and name the step that could have stopped them.

> Your answer:

The attacker obtains MINTER_ROLE and calls mint(attacker,1_000_000e6). Their balance and total supply increase without any collateral entering Vault. They then call Vault.redeem; this implementation requires no sUSD approval because Vault has privileged burn authority.

Full redemption succeeds only if Vault holds at least 1,000,000 USDC. Vault first checks its reserve balance, burns the caller's tokens, and transfers equal collateral. If the amount exceeds reserves, InsufficientCollateral reverts the entire transaction before burning or paying anything. In the recorded experiment, reserves are only 1,000 USDC, so redeeming one million fails. Redeeming 1,000 instead can empty those reserves, leaving legitimate holders without backing and the attacker with unbacked tokens.

The decisive prevention point is granting mint authority: only collateral enforcing contracts should receive it. A governance multisig, timelock, issuance caps, and monitoring reduce compromise risk. Checking reserves during redemption prevents excessive withdrawals, but cannot distinguish fraudulent tokens from legitimate tokens already in circulation.

---

## D. Toward RWA

**D1.** Right now the collateral is `MockUSDC` and `totalCollateral()` just reads an on-chain balance — simple and reliable. If the collateral were **US Treasuries**, could this invariant still be written that way? What new problems appear?

> Your answer:

An ERC20 balance alone cannot establish Treasury backing. A tokenized Treasury claim depends on a custodian holding securities and on enforceable rights to them. Reporting must identify ownership, encumbrances, quantities, market prices, accrued interest, and any haircut used to cover valuation risk.

The invariant should compare supply against available reserve value in matching units, for example riskAdjustedCollateralValue >= stableSupply. Face value is insufficient because interest rate changes alter sale prices. Reports need timestamps and freshness limits; stale or manipulated valuations can make an apparently solvent system issue too many tokens.

Solvency also differs from liquidity. Securities may require sale and settlement before dollars can reach redeeming holders. A cash buffer and clear withdrawal timing are therefore necessary even when total reserve value is sufficient.

Custodian failures, reporting errors, and legal claims cannot be resolved by Solidity alone. Attestations, reconciliation, custody agreements, and insolvency procedures become part of maintaining credible backing.

**D2.** If the collateral were **a building**, how would you put it inside this vault? Which off-chain roles or legal structures would you have to introduce?

> Your answer:

A building would need a legal wrapper rather than a direct deposit. An SPV or trust would own the property, and a token would represent defined rights in that entity. Documentation must specify whether holders own equity, secured debt, or a claim on rental cash flows; those rights have different repayment priorities.

A trustee or administrator manages the ownership structure. A property manager handles tenants, maintenance, insurance, and rent. Appraisers estimate value, while auditors check ownership and liabilities. Lawyers establish enforceable claims, title transfers, creditor priority, and treatment of insolvency.

Vault accounting would track tokenized claims and a conservative net valuation after mortgages, taxes, expenses, and haircuts. An appraisal still cannot guarantee a buyer at that price.

Buildings cannot fund instant redemptions through token burning alone. The design needs liquid reserves, withdrawal queues, and sale procedures, with disclosed settlement delays and loss allocation if sale proceeds cannot cover stablecoin claims.

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
