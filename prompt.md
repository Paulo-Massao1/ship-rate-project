2. Apply uppercase formatter to search_ship_page.dart (same _UpperCaseTextFormatter pattern used in add_rating_page.dart)

3. Improve UX in add_rating_page.dart for existing ships:
- When user types a ship name that ALREADY EXISTS in database, show message below field: "✓ Ship found - tap to rate"
- Highlight dropdown with green border when there's a match
- Block saving if ship name exists but user didn't select from dropdown (show error)
- Add PT and EN translations to .arb files

Run flutter analyze after changes.