## Purpose

Defines Raspberry Pi–compatible deployment constraints, SQLite persistence, indexing expectations, runtime binding, asset deployment, secrets handling, and application time zone for date-sensitive features.

## Requirements

### Requirement: Raspberry Pi compatible architecture
The application MUST remain suitable for a Raspberry Pi 4-class server with approximately 4 GB RAM. The architecture SHOULD minimize infrastructure dependencies. SQLite MUST remain an acceptable production database. The system MUST NOT require PostgreSQL, Redis, Elasticsearch, a vector database, Sidekiq, or an AI runtime unless introduced by a future approved specification.

#### Scenario: SQLite production database
- **WHEN** PRM is deployed for normal production use on the Pi-class host
- **THEN** SQLite MUST be an acceptable production persistence technology without requiring PostgreSQL

### Requirement: Persistent database storage
Database data MUST reside on persistent storage rather than ephemeral application-build storage. Deployment changes MUST preserve persistent SQLite data. Persistent database location and application source location MUST NOT be conflated.

#### Scenario: Restart preserves data
- **WHEN** the application process restarts after deployment
- **THEN** existing People and Entries in the persistent SQLite database MUST remain available

### Requirement: Indexing expectations
Frequently queried relationship and date fields MUST be indexed where practical, including equivalents of entries.occurred_on, entries.primary_person_id, entry_people.entry_id, entry_people.person_id, entry_tags.entry_id, entry_tags.tag_id, people.name, and tags.name. Exact table names MAY differ.

#### Scenario: Occurred_on query path
- **WHEN** timelines and date-bounded Entry queries run against production data
- **THEN** occurred_on SHOULD benefit from an index on the Entry date field

### Requirement: Legacy persistence naming
The current schema uses Entry-oriented persistence names such as entries, entry_people, and entry_tags. Legacy names such as notes MUST NOT automatically redefine the product domain. Implementation work MUST inspect the actual schema before any migration renames persistence objects. Schema normalization or renaming requires a future OpenSpec change.

#### Scenario: No rename for terminology alone
- **WHEN** persistence names already match Entry terminology
- **THEN** agents MUST NOT introduce renames solely to satisfy older documentation that mentioned notes

### Requirement: Production process and network binding
The production application is expected to run under Rails or Puma managed by systemd. Puma binding and Cloudflare Tunnel routing MUST agree. If Puma binds only to 127.0.0.1, a containerized Cloudflare Tunnel MUST NOT be configured to reach the application through a different host-network address that cannot access that listener. The application's health endpoint SHOULD remain usable for deployment verification.

#### Scenario: Binding agreement
- **WHEN** Puma listens only on 127.0.0.1
- **THEN** tunnel or reverse-proxy configuration MUST reach that listener rather than an unreachable alternate address

### Requirement: Production assets
Changes to JavaScript or CSS MUST be reflected in production after deployment. Production deployment documentation MUST identify whatever build or precompile step the current implementation requires before service restart. A plain git pull plus service restart MUST NOT be documented as sufficient if compiled production assets would remain stale. Secrets such as SECRET_KEY_BASE MUST NOT be committed merely to allow asset compilation.

#### Scenario: Asset-aware deploy docs
- **WHEN** frontend assets change and production is updated
- **THEN** deployment steps MUST include any required asset build or precompile before relying on the restarted service

### Requirement: Configuration and secrets externalization
Deployment-specific values SHOULD be externalized, including APP_TIME_ZONE, DATABASE_PATH, calendar credentials, and Rails secrets. Secrets MUST NOT be committed to source control. Secrets MUST NOT be stored as ordinary user-editable PRM configuration values.

#### Scenario: Secret not in PRM config UI
- **WHEN** an operator manages SECRET_KEY_BASE or calendar credentials
- **THEN** those values MUST NOT be stored as ordinary user-editable PRM configuration fields in the app UI

### Requirement: Application time zone
Features depending on today MUST use the configured application time zone. This includes Recent Timeline, current ISO week, three-month historical calculation, and 30-day operational statistics where calendar boundaries matter. The expected deployment time zone is America/Los_Angeles unless deployment configuration explicitly overrides it.

#### Scenario: Today uses configured zone
- **WHEN** APP_TIME_ZONE is America/Los_Angeles and local clock crosses midnight in that zone
- **THEN** Recent Timeline's today MUST follow that configured zone rather than an unrelated host-local zone
