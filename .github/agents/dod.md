# Definition of Done (DoD)

A feature, fix, or change is NOT complete unless ALL of the following are satisfied.

---

## 1. Engineering Standards Compliance

- Implementation complies with agents/engineering-standards.md.
- No architectural violations introduced.
- No cross-layer imports.
- No business logic inside controllers.
- No unnecessary refactoring of unrelated code.

---

## 2. Documentation

- README.md updated (if behavior changes).
- requirements.md updated (if scope changes).
- architecture.md updated (if structure changes).
- deployment.md updated (if infra changes).
- API documentation (OpenAPI/Swagger) updated.
- .env.example updated (if new environment variables introduced).

If documentation does not reflect reality, feature is incomplete.

---

## 3. Security Verification

- No hardcoded secrets.
- No secrets committed to repository.
- Inputs validated.
- Parameterized queries used.
- OWASP Top 10 risks reviewed.
- Public endpoints protected with authentication (if required).
- Rate limiting applied to public APIs.
- CORS configuration reviewed.
- Logs contain no sensitive data.

Security review must be explicit, not assumed.

---

## 4. Testing

- Unit tests added for new logic.
- Existing tests pass.
- Critical flows covered by integration tests.
- Edge cases considered.
- No flaky tests introduced.

If no tests exist, add minimal coverage for new logic.

---

## 5. Observability

- Errors logged with context.
- Structured logging used.
- Correlation IDs preserved.
- Health endpoint verified.
- Application Insights (or equivalent) enabled in production.

---

## 6. Infrastructure

- Infrastructure changes defined in Bicep or Terraform.
- No manual cloud configuration.
- Deployment tested in staging before production.
- Estimated monthly cost documented for new resources.

---

## 7. Performance & Stability

- No blocking synchronous calls in async flows.
- No obvious performance regressions.
- Resource usage reasonable.
- No unnecessary allocations or heavy loops.

---

## 8. Dependency Review

- No unnecessary dependencies introduced.
- Dependency versions locked.
- Vulnerability scan completed.
- No abandoned/unmaintained libraries added.

---

## 9. Change Discipline

If change affects:
- Architecture
- Data model
- Public API
- Infrastructure

Documentation updated accordingly.

---

## 10. Final Sanity Check

Ask:

- Would a senior engineer approve this?
- Is the solution the simplest viable implementation?
- Is anything hacky?
- Does this introduce future technical debt?

If yes — fix it before marking done.