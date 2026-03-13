# Change Request

## 1. Summary
Describe the requested change clearly.

Is this:
- Bug fix
- Behavior modification
- Performance improvement
- Refactor
- Breaking change

---

## 2. Current Behavior

Describe how the system currently behaves.

---

## 3. Desired Behavior

Describe expected behavior after change.

---

## 4. Impact Analysis (Mandatory)

You MUST explicitly analyze:

### A. Impacted Layers
(API / Domain / Infrastructure / Web / Mobile)

### B. Backward Compatibility
- Does this change API contracts?
- Does this affect existing users?
- Does version bump required?

### C. Data Impact
- Schema changes?
- Migration required?
- Risk of data loss?

### D. Security Impact
- Does this alter auth?
- Does this introduce new inputs?
- Does OWASP risk profile change?

### E. Performance Impact
- Latency impact?
- Load implications?
- Resource usage changes?

---

## 5. Documentation Updates Required

- README.md
- requirements.md
- architecture.md
- deployment.md
- OpenAPI/Swagger

---

## 6. Implementation Rules

- Must comply with agents/engineering-standards.md
- Must satisfy agents/dod.md
- Must not expand scope
- Must not refactor unrelated code

---

# Post-Implementation Verification

After implementation, explicitly:

1. Validate against agents/dod.md.
2. Confirm no regression introduced.
3. Confirm documentation updated.
4. Confirm security review completed.
5. Confirm tests updated or added.