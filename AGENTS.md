# Project context

> IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning

- Educational Foundry stablecoin lab; Solidity 0.8.24 and vendored OpenZeppelin 5.0.2 / forge-std.
- Core loop: MockUSDC -> Vault.deposit -> SimpleStablecoin.mint; Vault.redeem burns caller tokens and returns collateral.
- Ex5: OverCollateralizedVault uses 18-decimal collateral, 8-decimal price, 6-decimal debt; conversion divides by 1e20.
- The broad burn role and global pause behavior are intentional teaching targets. Preserve Ex4 semantics unless explicitly asked to redesign them.
- The assignment PDF overrides generic README labels: Tier2 is 20%, Ex1 ungraded, Ex7 optional; submission is a ZIP retaining lib/.
- Do not treat historic notes as proof of current runtime results. Do not label chain bytecode presence as explorer source verification.
- Real wallet/API credentials never belong in tracked files, screenshots or submission archives.
- Docs: README.md (architecture/setup), EXERCISES.md (task statements), STUDENT-QUESTIONS.md (answers).
- Audit: ASSIGNMENT_REVIEW.md, evidence/README.md, evidence/verification-2026-10-05.txt, MOODLE_LINKS.md.
- Session: task_plan.md, progress.md, findings.md.
- New features must follow the user's documentation-first requirements; the current task is an assignment review with no business-code changes.
