
Change crew nationality field in add_rating_page.dart and edit_rating_page.dart:

From text input to multi-select chips with options:
- Filipino, Russian, Ukrainian, Indian, Chinese, Brazilian
- "Other" option that opens a text field to specify

Allow selecting multiple nationalities.
Save to Firestore as list of strings.
Update rating_detail_page.dart and search_ship_page.dart to display correctly.
Add PT and EN translations to .arb files.
Run flutter analyze after changes.