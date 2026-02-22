Create CLAUDE.md file in the project root with these rules:

# CLAUDE.md

## Project: ShipRate
Ship evaluation app for maritime pilots in Brazil.

## Code Standards:
- Clean code with organized sections (CONSTANTS, STATE, LIFECYCLE, METHODS, BUILD)
- Comments in English
- All user-facing text must use i18n (app_pt.arb and app_en.arb)
- Run flutter gen-l10n after adding i18n keys
- Update ALL pages where changed data appears

## Architecture:
- Controllers in lib/controllers/ (business logic only)
- Pages in lib/features/ (UI only)
- Services in lib/data/services/
- Reuse existing patterns from similar files

## Quality Checks:
- Always use best practices and scalable solutions
- Before implementing, consider: Is this the best approach? Are there better alternatives?
- Avoid workarounds - implement proper solutions
- Run flutter analyze after changes

## Testing:
- Test with: flutter run -d chrome --release
- Verify changes work on web before committing

