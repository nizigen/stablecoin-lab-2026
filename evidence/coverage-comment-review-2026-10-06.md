# Coverage and comment review — 2026-10-06

The official exercise acceptance tests passed on 2026-10-05. Coverage instrumentation emitted anchor warnings, so the percentages alone are not a reliable map of missing behavior. The following gaps were found by independently reading actual test calls and assertions.

| Priority | Contract / scenario | Test to add |
|---|---|---|
| High | OverCollateralizedVault.repay | Partial/full repayment; debt and supply both decrease; excess repayment and insufficient sUSD balance revert without state changes. There is no current test invocation of repay. |
| High | Liquidation threshold | 1e18 collateral, 1000e6 debt, price1200e8 must reject liquidation; price1200e8-1 must allow it. Existing tests only exercise200%,110%,100%. |
| High | Failed liquidation | A liquidator without enough sUSD must not change the borrower's debt, collateral, token balances or supply despite mapping updates preceding burn. |
| Medium | Bonus below collateral cap | At119% collateral ratio, check seized collateral, rounding, the borrower's retained collateral, and actual vault balance. Existing successful cases seize everything. |
| Medium | Failed mint/withdrawal | Add post-revert assertions proving updated mappings, balances and supply fully roll back. Current tests mainly assert the revert selector. |
| Medium | Permission and pause recovery | Unauthorized pause/unpause; successful unpause restores operations; paused mint/deposit rolls back the collateral transfer. |
| Medium | Exact mint boundary | With2000e6 collateral value,1333333333 debt units succeeds and1333333334 fails. Existing1333e6/1334e6 cases are coarse boundary checks. |
| Lower | Input/asset errors | Zero inputs, missing allowance/balance, excessive withdrawals, nonpositive feed prices and transferred sUSD redeemed by its new holder. |

These are quality improvements, not failures of the PDF's supplied exercise acceptance suite. No new test behavior was added in this review.

Previous commit0c8dac0 revised README and discussion answers, not executable-source comments. The present review corrects only inaccurate/stale comments in OverCollateralizedVault.sol and exercise test files01/02/03: completedTODO narratives,1000e18 unit conversion, coarse versus exact boundaries, existing nonpositive-price checking, and liquidation reward shortfall versus economic insolvency. This liquidation model burns the whole debt and does not retain a protocol bad-debt balance; when collateral is worth less than repayment, a willing liquidator bears a loss, or liquidation may not occur.

Deployment source identity is preserved for the core Vault: src/Vault.sol was not edited and matches Sourcify's registered source. Changes to exercise comments do not change executable tokens, but compiling them changes metadata/source hashes; the already-deployed core Vault was not redeployed.
