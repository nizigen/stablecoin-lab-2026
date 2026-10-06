# Evidence index

Latest Codespace review (2026-10-06):

- [codespace-review-2026-10-06.md](codespace-review-2026-10-06.md): actual runtime and safe `.env`/credential-copy checks, scope and limitations.
- [codespace-all-green-2026-10-06.png](codespace-all-green-2026-10-06.png): real `make test` and `make exercise` logs filtered to PASS/results; core7 and exercises18 pass on HEAD210d9ff with Forge1.8.3.
- [codespace-invariants-2026-10-06.png](codespace-invariants-2026-10-06.png): both Ex6 properties, 256 runs, 128000 calls, zero reverts.
- [codespace-env-audit-2026-10-06.png](codespace-env-audit-2026-10-06.png): metadata and scan results only, no credential values; `.env` ignored/untracked, permissions0600, RPC URL copied in ignored cache.

- [ex3-unbacked-mint.png](ex3-unbacked-mint.png): original screenshot from 2026-10-02. Same image shows successful privileged mint, supply 1001000000000, collateral 1000000000 and attacker balance. Recovered from the Typora image referenced in the user's downloaded EXERCISES.md. Not recreated or altered.
- [ex4-five-tests.png](ex4-five-tests.png): original 2026-10-02 five Ex4 PASS results.
- [ex5-ten-tests.png](ex5-ten-tests.png): original 2026-10-02 ten Ex5 PASS results.
- [sepolia-verification-record.png](sepolia-verification-record.png): original 2026-10-02 output confirming MockUSDC and SimpleStablecoin already verified on Etherscan. Its truncated Vault result is supplemented by the 2026-10-06 Etherscan page below.
- [verification-2026-10-05.txt](verification-2026-10-05.txt): actual rerun with Foundry v1.8.4 against source HEAD 210d9ff. Records versions, commands, outputs and exit codes. Core/exercises/challenge pass; coverage includes warnings; formatter reports existing differences.

The files above are portable repository-relative evidence. Historical screenshots and the current execution transcript have different dates; neither should be relabeled as a new terminal screenshot.

2026-10-06 supplementary review:

- [vault-source-match-2026-10-06.json](vault-source-match-2026-10-06.json): Sourcify exact creation/runtime verification and registered/local Vault source comparison.
- [vault-etherscan-verified-2026-10-06.png](vault-etherscan-verified-2026-10-06.png): actual Chrome capture of the recorded Sepolia Vault address showing Source Code Verified / Exact Match, contractVault, compilerv0.8.24+commit.e11b9ed9, optimizer200runs and EVMcancun; independently inspected.
- [vault-live-checks-2026-10-06.txt](vault-live-checks-2026-10-06.txt): read-only Sepolia configuration and expected-revert calls; no transaction was sent.
- [coverage-comment-review-2026-10-06.md](coverage-comment-review-2026-10-06.md): concrete missing test behaviors and comment-only corrections.
- [secret-scan-2026-10-06.md](secret-scan-2026-10-06.md): current-file/local-history and screenshot secret review, known public fixtures and limits.
- [comment-verification-2026-10-06.txt](comment-verification-2026-10-06.txt): independent comment/token comparison and exercise regression; 18 tests pass, both invariant properties pass across 128000 calls.
