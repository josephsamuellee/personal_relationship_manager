## ADDED Requirements

### Requirement: Persistent draft table on SQLite
Production deployments MUST apply the unfinished Entry draft schema to the persistent SQLite database used by the application. Draft data MUST reside on the same persistent storage class as committed Entries. The system MUST NOT require Redis or another external datastore for unfinished drafts.

#### Scenario: Migrate before relying on drafts
- **WHEN** an operator deploys a release that introduces durable unfinished drafts
- **THEN** deployment steps MUST include migrating the persistent SQLite database before users rely on Save or person-resolution staging

### Requirement: Cookie draft cutover
Deploying durable drafts MUST document that previously cookie-staged session drafts are not migrated and may be lost at cutover. Operators SHOULD finish or discard in-progress resolution before upgrading when feasible.

#### Scenario: Pre-upgrade unfinished cookie draft
- **WHEN** a user had only a cookie-staged draft before upgrade and no durable draft row exists
- **THEN** that cookie draft MUST NOT be required to survive cutover

### Requirement: Journal content log filtering
Production logging MUST filter Entry and unfinished-draft Markdown body parameters (and equivalent nested param keys) so routine request logs do not retain full journal bodies.

#### Scenario: Draft body not logged in full
- **WHEN** a request submits a long unfinished-draft Markdown body
- **THEN** filtered production logs MUST NOT include the full body plaintext
