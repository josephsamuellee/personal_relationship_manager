## Purpose

Defines application-wide Dark and Light themes, with Dark as the default unless Light is explicitly selected and persisted.

## Requirements

### Requirement: Dark and light themes
The application MUST support Dark and Light themes. The default MUST be Dark unless configuration explicitly selects Light. Theme configuration MUST persist across normal requests and restarts according to the application's existing configuration persistence mechanism.

#### Scenario: Default dark theme
- **WHEN** no theme preference has been configured
- **THEN** the application MUST render using Dark

#### Scenario: Persist light theme
- **WHEN** the user selects Light on the configuration page
- **THEN** subsequent normal requests MUST continue rendering Light until changed again

### Requirement: Application-wide theme
The selected theme MUST apply consistently across normal application pages.

#### Scenario: Theme on Person and Entry pages
- **WHEN** Light theme is selected
- **THEN** homepage, Person pages, Entry pages, search, and configuration MUST all render with Light
