# Feature Request

## 1. Summary
Provide a clear, concise description of the feature.

---

## 2. Functional Requirements

List explicit, testable requirements.

- FR1:
- FR2:
- FR3:

Each requirement must be independently verifiable.

---

## 3. Non-Functional Requirements

- Performance expectations:
- Security requirements:
- Expected load:
- Availability requirements:
- Cost constraints (if applicable):

---

## 4. Constraints

- Must comply with agents/engineering-standards.md
- Must satisfy agents/dod.md
- Must not refactor unrelated code
- Must not expand scope beyond defined requirements

---

# Copilot Mandatory Workflow

You MUST follow this structure in your response:

## A. Impacted Layers
(API / Domain / Infrastructure / Web / Mobile)

## B. Architecture Plan
- Describe how the feature fits current architecture
- Justify design decisions
- Confirm layered architecture compliance

## C. Security Considerations
- Authentication/authorization impact
- Input validation requirements
- OWASP Top 10 review
- Rate limiting impact
- Sensitive data handling

## D. Infrastructure Impact
- New Azure resources required?
- Changes to existing services?
- Cost impact?
- Bicep/Terraform updates required?

## E. Documentation Updates Required
- README.md
- requirements.md
- architecture.md
- deployment.md
- OpenAPI/Swagger
- .env.example (if needed)

## F. Implementation

Provide implementation only after sections A–E are complete.

Do not modify unrelated files.

---

# Post-Implementation Verification

After implementation, explicitly:

1. Validate against agents/dod.md checklist.
2. Confirm documentation updates.
3. Confirm security review completion.
4. Confirm architectural compliance.
5. Confirm testing coverage added.
6. Confirm infrastructure alignment.

If any section is incomplete, the task is NOT done.