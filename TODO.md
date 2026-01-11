# TODO: Implement Book Now Button Process

## Pending Tasks
- [x] Update imports and add variables in booking_screen.dart (UserModel, currentUser, guides, selectedGuide)
- [x] Add _fetchCurrentUser() and _fetchGuides() methods in initState
- [x] Restructure body to always show Form with sections: select tour, select guide, participants, contact, date, terms, summary, submit
- [x] Implement _buildSelectTourSection() with compact container and dialog
- [x] Implement _buildSelectGuideSection() similar to tour_details_screen.dart
- [x] Modify _buildParticipantSection() to show read-only user name first, then add participant for additional
- [x] Change contact validator to exactly 11 digits
- [x] Modify booking summary to show subtotal and final total, hide service fee; update calculations
- [x] Update submit button to disable if no tour or guide selected
- [x] Update _submitBooking() to include user in participants and use final total
- [x] Test the flow from main dashboard Book Now to booking screen
