## Purpose

Defines the three ordered Favorite People homepage slots, assignment from Person pages, landscape and portrait presentation, and alphabetical See All People.

## Requirements

### Requirement: Favorite People section
The homepage MUST provide a Favorite People section near the top. The system MUST support three ordered favorite positions 1, 2, and 3. Each position MAY be empty. By default, no Person MUST be required to occupy a favorite position.

#### Scenario: Empty favorites by default
- **WHEN** no favorite assignments have been saved
- **THEN** favorite positions 1 through 3 MAY be empty and the homepage Favorite People section MUST still render

### Requirement: Favorite assignment on Person pages
Person pages MUST provide a control allowing the Person to be assigned Not favorited, 1, 2, or 3. Changing the selection MUST NOT become persistent until the applicable save or update action is performed. A favorite position MUST represent at most one Person.

#### Scenario: Assignment requires save
- **WHEN** the user changes the Favorite People dropdown on a Person page without saving
- **THEN** the homepage favorite slots MUST NOT yet reflect that change

### Requirement: Favorites not edited on configuration page
The configuration page MUST NOT independently expose favorite-Person selection when favorite assignment occurs from Person pages.

#### Scenario: Config explains Person-page assignment
- **WHEN** the user opens the configuration page
- **THEN** favorite slots MUST NOT be editable there and the page SHOULD explain that favorites are set on Person pages

### Requirement: Landscape presentation
On sufficiently wide displays, Favorite People MUST present four conceptual items horizontally: Favorite 1, Favorite 2, Favorite 3, and See All People.

#### Scenario: Wide layout four destinations
- **WHEN** the homepage is viewed on a sufficiently wide display
- **THEN** Favorite People SHOULD present the three favorite slots and See All People as four horizontal destinations

### Requirement: Portrait presentation
On portrait or narrow displays, the same four destinations MUST be represented compactly as links rather than requiring the desktop layout.

#### Scenario: Narrow favorite links
- **WHEN** the homepage is viewed on a portrait or narrow display
- **THEN** the three favorite destinations and See All People SHOULD remain reachable as compact links

### Requirement: See All People alphabetical
The Favorite People section MUST contain a See All People destination. Selecting it MUST open a page containing all People sorted alphabetically by name. Each Person MUST link to that Person's page.

#### Scenario: Alphabetical people list
- **WHEN** People named Jerry, Andrew, and Carolyn exist and the user opens See All People
- **THEN** the display order MUST be Andrew, Carolyn, Jerry and each name MUST link to that Person's page
