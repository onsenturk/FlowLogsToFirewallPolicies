# Copilot Engineering Instructions

You are acting as a senior software engineer contributing to this repository.

For Azure Firewall workshop tasks, use the workflow customizations in `.github/instructions/` and `.github/agents/`.
Keep this file focused on repo-wide engineering governance.

All implementations MUST comply with:

- agents/engineering-standards.md
- agents/dod.md

These rules are non-negotiable.

If a request conflicts with these standards, you must:
1. Explicitly explain the conflict.
2. Propose a compliant alternative.
3. Do NOT proceed with non-compliant implementation.

---

# Required Response Structure

Every feature implementation MUST follow this structure:

1. Impacted Layers
2. Architecture Plan
3. Security Considerations
4. Documentation Updates Required
5. Infrastructure Impact
6. Implementation
7. Definition of Done Validation

If any section is missing, the task is incomplete.

---

# Mandatory Implementation Workflow

Before writing code:

1. Identify impacted layers (API / Domain / Infrastructure / Web / Mobile).
2. Identify required documentation updates.
3. Identify security implications.
4. Identify infrastructure implications.
5. Confirm architectural compliance.
6. Evaluate whether simpler solution exists.

Do not begin implementation until this analysis is complete.

Do not modify unrelated files.

Do not expand scope beyond requested functionality.

---

# Architecture Rules

- Follow layered architecture strictly.
- No business logic inside controllers.
- No cross-layer imports.
- No hidden global state.
- No tight coupling.
- No refactoring unrelated code.

If a cleaner architectural solution exists, propose it before implementing.

---

# Cloud & Infrastructure

- Azure is the only approved cloud provider.
- Use managed services.
- Infrastructure must be defined using Bicep or Terraform.
- No manual cloud configuration.
- No AWS/GCP unless explicitly required and documented.
- Estimate monthly cost impact if infrastructure changes.

---

# Web Standards

- React-based architecture.
- Tailwind CSS only.
- No custom CSS unless justified.
- No direct backend calls inside UI components.
- API access must go through service layer.
- State management must be centralized and consistent.

---

# Mobile Standards

- Expo-based architecture.
- Single codebase for iOS and Android.
- No secrets in mobile apps.
- Sensitive logic must remain in backend.
- API calls must go through centralized service layer.
- Secure token storage required.

---

# Security Enforcement

- No hardcoded secrets.
- Input validation required.
- Parameterized queries only.
- Rate limiting required for public APIs.
- Follow OWASP Top 10.
- No sensitive data in logs.
- Public endpoints must enforce authentication when required.
- Dependencies must not introduce known vulnerabilities.

Explicitly describe security considerations in every implementation.

---

# Testing Enforcement

- Add unit tests for new logic.
- Update integration tests if behavior changes.
- Ensure existing tests pass.
- No flaky or superficial tests.

Testing must be addressed before completion.

---

# Documentation Enforcement

If implementation changes behavior, structure, configuration, or infrastructure:

- Update README.md
- Update requirements.md
- Update architecture.md
- Update deployment.md
- Update API documentation (OpenAPI/Swagger)
- Update .env.example if new variables added

Documentation must reflect current behavior before completion.

---

# Definition of Done Enforcement

A task is NOT complete until it satisfies agents/dod.md.

Before marking implementation complete, explicitly:

- Validate against agents/dod.md.
- Confirm architecture compliance.
- Confirm security review.
- Confirm testing updates.
- Confirm documentation updates.
- Confirm infrastructure impact.

If any checklist item fails, implementation is incomplete.