# Tour Guide Dashboard Earnings Calculation Update

## Completed Tasks
- [x] Add TourModel import to tour_guide_dashboard_tab.dart
- [x] Modify _loadOverviewStats method to calculate earnings based on tour inclusionPrices
- [x] Filter bookings with status paid (2) or completed (4)
- [x] For each booking, fetch tour and sum inclusionPrices values
- [x] Calculate guide's share as 95% of total inclusionPrices (deduct 5%)
- [x] Accumulate total earnings across all relevant bookings

## Follow-up Steps
- [ ] Test the dashboard to ensure earnings display correctly
- [ ] Verify that tours with inclusionPrices are handled properly
- [ ] Check for any edge cases (empty inclusionPrices, missing tours)
- [ ] Ensure the calculation performs well with multiple bookings

## Notes
- Earnings now calculated as: sum of (tour.inclusionPrices total * 0.95) for each paid/completed booking
- Previous calculation used booking.totalPrice directly
- Added async tour fetching in the loop - monitor performance
