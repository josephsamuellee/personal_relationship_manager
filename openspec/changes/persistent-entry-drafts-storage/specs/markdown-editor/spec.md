## ADDED Requirements

### Requirement: Long Markdown through resolution
Entry Markdown submitted through the shared editor MUST remain exactly preservable when Save stages a durable unfinished draft for person resolution, including bodies around 1 KB, 4 KB, 16 KB, and 64 KB and multibyte Unicode such as Traditional Chinese. Staging MUST NOT fail solely because of browser cookie capacity.

#### Scenario: Large unresolved body preserves Markdown
- **WHEN** the user submits Save from the Entry editor with an unresolved person reference and a Markdown body of approximately 16 KB including Traditional Chinese characters
- **THEN** the durable draft MUST retain that exact Markdown string for Preview and later Save

#### Scenario: Large valid body still saves
- **WHEN** the user submits Save from the Entry editor with a fully valid draft whose Markdown body is approximately 64 KB and all people are recognized
- **THEN** the Entry MUST persist with that exact Markdown and MUST NOT require cookie-based draft staging
