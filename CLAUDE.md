## Golden rules (team)
- Committed means pushed: if it's committed, it's pushed.
- Hold irreversible actions — merge, force-push, close — for explicit approval.
- reference/ is always read-only.
- The canonical issue burn-down index table is the single source of truth.

## planned_execution.md
- The sequenced execution view, DERIVED from the burn-down index table and
  GitHub issues. Those stay authoritative for completion state; this file never
  competes with them.
- Session start: read it and report current phase + next unstarted item before
  proposing work.
- On issue close or PR merge: mark the matching item done (with PR/evidence
  link), refresh NEXT UP and LAST SESSION, then commit and push.
- DEFERRED (pending school hardware allocation): Step 0.4 (so-install-runbook
  values); Standalone Security Onion deployment.