# Currency Conversion Implementation

## Tasks
- [x] Add JOD currency to the currencies map in settings_screen.dart
- [x] Update getCurrencySymbol() method in app_provider.dart to include JOD symbol
- [x] Add exchange rates map in app_provider.dart
- [x] Add convertAmount method in app_provider.dart for currency conversion
- [x] Add convertAllDataToNewCurrency method in app_provider.dart to convert all stored amounts when currency changes
- [x] Update currency change logic in settings_screen.dart to trigger conversion
- [x] Test the conversion functionality

## Notes
- All amounts are currently stored in the selected currency
- When changing currency, convert all transactions, goals, and installments to the new currency
- Use approximate exchange rates relative to USD
- JOD symbol: د.أ or JD
