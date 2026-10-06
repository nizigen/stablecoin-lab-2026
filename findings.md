# Findings

- PDF: contract correctness/testing 40%; Sepolia deployment AND source verification 20%; threat-model answers 25%; style/documentation 15%.
- README calls Tier 2 bonus but PDF requires it for the 20% category. PDF overrides repository tutorial descriptions.
- Source clone HEAD: 210d9ff57b14b8d0894c2ef179b8bbb8a3ff5a86.
- Downloaded EXERCISES.md contains private-machine Typora image links, not portable submission evidence.
- Ex3 recorded supply 1,001,000 sUSD vs 1,000 mUSDC, but no linked Ex3 screenshot in the provided notes.
- Existing Codespace is initially Shutdown; verification lane must stop it again if started.
- Windows shell has no forge/cast/anvil; test statements require runtime evidence, not screenshots alone.

## Verification and independent review

- Actual native Foundry v1.8.4 rerun: doctor6/core7/exercises18/challenge2 passed. Ex6 properties both PASS with256runs128000calls and0reverts.
- Coverage summary: lines82.79/statements78.39/branches36.59/functions85.11%; anchor warnings retained, not a blanket80% claim.
- Original Ex3 screenshot found and recovered; also Ex4/Ex5 and Sepolia screenshots. Sepolia screenshot proves first two already verified but omits Vault final result.
- All three Sepolia addresses have runtime bytecode on 2026-10-05 publicRPC read; this does not prove Etherscan verification.
- Answer author and independent reviewer corrected A1 caller+allowance+balance, C2 reserve-limited redemption; all8answers150 whitespace words.
- No business source/test changes; git diff check passes; original forge fmt reports6files.

2026-10-06 follow-up checkpoint: User requested direct Vault checks, concrete coverage gaps, comment clarity and secret review. Public RPC confirms configured tokens, Vault minter role, empty supply/reserves and expected zero/excess-amount reverts without transactions. Sourcify reports creation/runtime exact_match verified2026-10-02T05:42:25Z; registered core Vault source equals local after newline normalization, compiler0.8.24 EVMcancun optimizer200. Etherscan page/API constraints initially prevented platform-specific confirmation. Independent audit identified repay/threshold/rollback/pause recovery gaps. Corrected only comments in four exercise files; executable tokens unchanged. Independent secret scan found no real user key; known public Anvil fixtures remain. Subsequent independent comment regression passed.

2026-10-06 Vault explorer confirmation: Actual Chrome access succeeded despite earlier automated request restrictions. [Saved Etherscan page](evidence/vault-etherscan-verified-2026-10-06.png), independently viewed, shows Vault at0xea7C998f2412c626331BC1d94D8EE433c7f99d29 as Source Code Verified / Exact Match, compilerv0.8.24+commit.e11b9ed9, optimizer200runs and EVMcancun. Combined with the historical first-two-contract verification records, all three Etherscan verification evidence items are now confirmed.

## Codespace evidence — 2026-10-06

Confirmed remote HEAD210d9ff / Forge1.8.3, core7 andexercises18 pass, both invariants128000calls0reverts. Actual.env is ignored/untracked and contains configured fields; mode0666 was tightened to0600. No actualprivatekey/APIkeycopy in792otherfiles or695reachablehistoryblobs; ignoredcache stores fullRPCURL, so exclude cache from submission. Screenshots contain metadata only. OpenCLI native Enter/Ctrl+C lacked virtual keyCodes; minimal external tool helper repair enabled actual xterm execution; no project dependency change. Details and scope: evidence/codespace-review-2026-10-06.md.
