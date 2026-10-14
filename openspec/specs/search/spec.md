## Purpose

Defines global deterministic Search across People, dates, and Entries, including bounded initial results and full reverse-chronological Entry result sets.

## Requirements

### Requirement: Search available throughout application
Normal application pages MUST expose the global Search control. The original interaction uses a floating control in the lower-left area. The control MAY expand to expose its search input.

#### Scenario: Search control on homepage
- **WHEN** the user is on a normal application page such as the homepage
- **THEN** the global Search control MUST be available

### Requirement: Deterministic search
Search MUST remain deterministic. Core search MUST NOT require embeddings, LLM query interpretation, semantic inference, or NLP date interpretation.

#### Scenario: Search without AI services
- **WHEN** no embedding or LLM service is available and the user runs a search
- **THEN** deterministic People, date, and Entry search MUST still function

### Requirement: Search categories
The primary search results page MUST support the established categories People, Timeline or date, and Entries. The initial search SHOULD show at most three results per category.

#### Scenario: Bounded initial results
- **WHEN** a category has more than three matches
- **THEN** the initial results SHOULD show at most three in that category and MUST provide a path to the full set when applicable

### Requirement: People search ordering
People search MUST prioritize exact match, then prefix match, then substring match.

#### Scenario: Exact match ranks first
- **WHEN** People search matches both an exact name and a longer substring-containing name
- **THEN** the exact match SHOULD rank ahead of weaker substring matches

### Requirement: Entry search
Entry search MUST be capable of matching relevant textual Entry information, including title, body Markdown, and Tags. Title matches SHOULD rank ahead of weaker body matches unless an equivalent deterministic ranking already exists.

#### Scenario: Title match
- **WHEN** an Entry title contains the search query
- **THEN** that Entry MUST be eligible to appear in Entry search results

### Requirement: Date search semantics
Date-like search queries MUST use the same strict unambiguous date semantics used elsewhere in the application. The system MUST NOT infer natural-language dates such as "last year's company party" unless introduced by a future specification.

#### Scenario: Natural language date rejected
- **WHEN** the user searches for `last year's company party`
- **THEN** the system MUST NOT treat that phrase as a resolved calendar date under current core search

### Requirement: See All Results preserves context
When a search category has additional matching results, that category MUST provide a See All Results or equivalent action. The action MUST preserve the original search query and the selected result category or filter.

#### Scenario: See All Entries preserves query
- **WHEN** the user selects See All Results for Entries after searching a query
- **THEN** the full results view MUST preserve that query and the Entries category

### Requirement: Full Entry results ordering
The complete Entry-results page MUST display all matching Entries rather than only the initial top three. Entry results MUST be ordered reverse chronologically by occurred_on descending so the most recent matching Entry appears first and the oldest last.

#### Scenario: Reverse chronological full Entry list
- **WHEN** multiple Entries match and the user opens full Entry results
- **THEN** Entries MUST appear with later occurred_on values before earlier ones

### Requirement: Full results linking
Full Entry search results MUST use a tabular or list representation suitable for scanning. Every returned Entry MUST provide a link to its Entry page. If more People match than fit in the initial People section, the user MUST be able to reach the complete matching People result set, and matching People MUST link to their Person pages.

#### Scenario: Full People results link to Person pages
- **WHEN** more People match than the initial People section shows and the user opens the complete People results
- **THEN** each matching Person MUST link to that Person's page
