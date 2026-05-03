# Contributing to RideChain

## Branch convention

```
main        — stable, deployed code
dev         — active development
feat/xxx    — new features
fix/xxx     — bug fixes
test/xxx    — test additions
docs/xxx    — documentation only
```

## Commit convention

```
feat:     new feature
fix:      bug fix
test:     add or update tests
docs:     documentation only
chore:    tooling, config, dependencies
refactor: code change without behavior change
```

## Pull request rules

- All PRs target `dev`, not `main`
- Must pass all CI checks before merge
- Smart contract changes require test coverage
- Breaking changes require whitepaper update

## Smart contract changes

Any change to contract interfaces must:
1. Update the corresponding interface file in `contracts/interfaces/`
2. Update affected test files
3. Update deployment script if constructor args change
4. Add an ADR in `docs/adr/` explaining the decision

## Security

Do not open public issues for security vulnerabilities.
Contact maintainers directly via commit-signed message.

