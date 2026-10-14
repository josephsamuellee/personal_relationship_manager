## Purpose

Defines hashtag Tag semantics for Entries, including normalization and the boundary that Tags are not People.

## Requirements

### Requirement: Hashtag semantics
The syntax `#church`, `#dinner`, and `#vacation` MUST represent Tags. Tags MUST NOT represent People.

#### Scenario: Tag extracted from Entry body
- **WHEN** an Entry body contains `#dinner`
- **THEN** the Entry MUST associate with a Tag whose normalized name corresponds to dinner

### Requirement: Case-insensitive tag normalization
Tag names MUST be normalized case-insensitively so equivalent spellings resolve to the same Tag.

#### Scenario: Case normalization
- **WHEN** Entries contain `#Church` and `#church` and tags are persisted
- **THEN** they SHOULD resolve to the same normalized Tag
