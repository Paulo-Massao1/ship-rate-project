Fix UX in add_rating_page.dart when ship already exists:

Current problem: IMO, date, and nationality fields still showing. Confusing.

Better approach:
- When _hasExactMatch is true AND user hasn't selected from dropdown:
  - Hide the ENTIRE "Dados do Navio" card except the ship name field
  - Show a centered, larger message: "Ship found — tap to select from the list"
  - Maybe add an icon (checkmark or info) to make it clearer
  - Save button stays disabled

Only show full form after user selects from dropdown.
Run flutter analyze after changes.