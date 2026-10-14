## Purpose

Defines the Personal Relationship Manager as a lightweight, single-user relationship knowledge base that stays useful without AI and navigates correctly regardless of hostname.

## Requirements

### Requirement: Personal relationship knowledge base
The system MUST provide a lightweight personal relationship knowledge base suitable for long-term Raspberry Pi operation, covering People, dated Entries, Entry-Person relationships, tags, chronological browsing, person history, deterministic search, configuration, and lightweight operational statistics.

#### Scenario: Core system operates without AI
- **WHEN** the application is running and no LLM, embedding service, Ollama instance, or external AI API is available
- **THEN** People, Entries, timelines, search, configuration, and editing MUST continue to function

### Requirement: Single-user deployment
The current PRM deployment MUST operate as a single-user application. Application-level user accounts or login MUST NOT be required. Authentication and network access control MAY be handled externally. Multi-tenancy is outside this specification.

#### Scenario: Unauthenticated local use
- **WHEN** a single operator accesses PRM on the configured host
- **THEN** core People and Entry workflows MUST be usable without an in-app login

### Requirement: Host-independent navigation
Internal application navigation SHOULD use relative URLs. The application MUST NOT depend on one hardcoded hostname.

#### Scenario: Access through different hostnames
- **WHEN** PRM is available through both LAN access and a Cloudflare Tunnel and the user follows an internal application link
- **THEN** the link MUST continue using the current host and MUST NOT redirect to a hardcoded production hostname

### Requirement: Canonical domain terminology
Canonical product terminology is Person, Entry, and Tag. Persistence-layer names MAY differ. An implementation table or model named Note MUST NOT change user-facing terminology from Entry solely because of the persistence name.

#### Scenario: User-facing Entry label
- **WHEN** the UI refers to a dated journal or relationship event
- **THEN** it MUST use Entry terminology rather than exposing legacy persistence names as the product term

### Requirement: Global Add Entry control
Normal application pages MUST expose an Add Entry control. The established UI places this as a floating control in the lower-right area. Selecting it MUST navigate to Entry creation. Floating controls MUST NOT permanently obscure page content.

#### Scenario: Add Entry from homepage
- **WHEN** the user selects the floating Add Entry control on a normal application page
- **THEN** the application MUST navigate to Entry creation

### Requirement: Responsive core destinations
Core functionality MUST remain usable on landscape desktop and portrait or narrow displays. Responsive presentation MAY differ. Behavior and accessible destinations MUST remain equivalent for Favorite People, Search, Add Entry, Recent Timeline, and People navigation.

#### Scenario: Narrow display access
- **WHEN** the user uses a portrait or narrow display
- **THEN** Favorite People, Search, Add Entry, Recent Timeline, and People navigation MUST remain reachable

### Requirement: Deferred functionality boundary
The following MUST NOT be treated as current core requirements unless introduced through a later OpenSpec change: AI relationship inference, embeddings or vector search, automatic semantic tagging, automatic relationship extraction, multi-user accounts, multi-tenancy, photo upload or storage, PiGallery2 integration, automatic Google Calendar to Entry import, calendar write operations, and sophisticated TODO or reminder semantics.

#### Scenario: Missing deferred feature is not a baseline defect
- **WHEN** photo upload or AI inference is absent
- **THEN** the baseline MUST still be considered intact for core People, Entry, search, and timeline behavior
