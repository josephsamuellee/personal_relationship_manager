# Acceptance scenario coverage

| Scenario | Coverage |
|---|---|
| A Editor dimensions | CSS assertion in `entries_controller_test` (Entry `24rem`, shared default `12rem`) |
| B Recent People ranking | `RecentPeopleQueryTest` + entries controller Recent People markup test |
| C Limited history | `RecentPeopleQueryTest` limit/uniqueness cases |
| D Insert at caret | `test/javascript/markdown_insert_test.mjs` |
| E Replace selection | `test/javascript/markdown_insert_test.mjs` |
| F Append fallback | `test/javascript/markdown_insert_test.mjs` |
| G Draft persistence | Entries controller save with wiki body; insert updates same `entry[body_markdown]` field |
| H Mobile interaction | Buttons are `type="button"` below Save; responsive grid CSS (`2` cols ≤640px, min tap height); no submit on click |
| I Existing workflow regression | Existing entries/people/markdown suites; Person About asserts no Recent People UI |

Manual spot-check recommended on a narrow viewport: tap a Recent People button and confirm insert without Save/navigation.
