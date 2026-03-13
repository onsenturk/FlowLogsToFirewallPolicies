# Engineering Standards

This document defines non-negotiable engineering standards for this repository.
All code, documentation, infrastructure, and deployments must comply.

---

## 1. Platform & Deployment Strategy

### Backend

- Azure is the default and only cloud provider unless explicitly approved.
- Prefer managed services over self-hosted infrastructure.
- Infrastructure must be defined using Bicep or Terraform, which relies on Azure Verified Modules (AVM) best practices
- No AWS/GCP services unless explicitly required and documented.

Default service choices:

- Web/API: Azure App Service or Azure Container Apps
- Containers: Azure Container Apps
- Database: PostgreSQL Flexible Server or CosmosDB
- Storage: Azure Storage (Blob)
- Secrets: Azure Key Vault

### Web Frontend

- React-based architecture preferred.
- Tailwind CSS is the default styling system.
- Avoid custom CSS unless strictly necessary.
- No CSS frameworks other than Tailwind unless justified.

### Mobile

- Expo (React Native + Expo) is the default mobile platform.
- Single codebase for iOS and Android.
- Native modules only when absolutely required.
- OTA updates preferred when possible.
- No secrets stored in mobile applications.
- Sensitive logic must reside in backend.

---

## 2. Architecture Principles

- Use layered architecture (API / Domain / Infrastructure).
- No business logic inside controllers.
- No cross-layer imports.
- External integrations must be isolated in infrastructure layer.
- Public interfaces must be explicit and stable.
- Avoid tight coupling and hidden global state.
- Prefer clarity over cleverness.
- Do not refactor unrelated code during feature implementation.

### Web & Mobile Architecture

- UI, business logic, and API integration must be separated.
- API communication must go through a dedicated service layer.
- No direct backend calls inside UI components.
- State management must be centralized and consistent.
- No ad-hoc global state.

---

## 3. Documentation Requirements

Every project must contain:

- README.md
- requirements.md
- architecture.md
- deployment.md
- .env.example
- Infrastructure-as-Code (Bicep/Terraform)
- API documentation (OpenAPI/Swagger)

Documentation must reflect current behavior.

If any required documentation is missing, the project is incomplete.

---

## 4. Security Requirements

- No hardcoded secrets.
- Secrets stored in Azure Key Vault or environment variables.
- Managed Identity preferred over connection strings.
- Input validation required for all external inputs.
- Parameterized queries only (no string-built SQL).
- CORS must not be overly permissive.
- HTTPS enforced.
- Dependencies must be scanned for vulnerabilities.
- Logs must not expose sensitive data.
- No public storage access unless explicitly required.
- Secure token storage required for mobile.
- All API calls must use HTTPS.
- Rate limiting required on all public APIs.
- Must follow OWASP Top 10 security principles.

---

## 5. Dependency Management

- Minimize dependencies.
- Do not introduce new dependencies without justification.
- Prefer mature, well-maintained libraries.
- Remove unused dependencies immediately.
- Lock dependency versions.

---

## 6. Non-Functional Requirements

- Services must include structured logging.
- Errors must be logged with context (no silent failures).
- Health endpoint required for services.
- Application Insights enabled for production deployments.
- Correlation IDs required for request tracing.
- Resource usage must be reasonable for expected traffic.
- Avoid over-provisioned Azure resources.
- Prefer consumption/serverless tiers where possible.
- Document estimated monthly cost for new infrastructure.
- Public API changes must maintain backward compatibility or bump version.
- Database schema changes require migration script.
- No destructive schema changes without migration plan.
- Default to simplest viable solution.
- Do not introduce microservices without strong justification.

---

## 7. Change Discipline

If a change affects:

- Architecture
- Data model
- Public API
- Infrastructure

Then:

- Update architecture.md
- Update deployment.md
- Document rationale in requirements.md

---

## 8. Definition of Done

A feature is not complete unless it passes all checks in dod.md.

All features must satisfy Definition of Done requirements before merge.