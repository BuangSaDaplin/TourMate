# Admin Tour Moderation Screen Updates

## Tasks
- [x] Update `_buildTourModerationCard` to conditionally show buttons based on `tourData['moderationStatus']`
- [x] Modify `_showModerationDialog` to handle 'reject', 'suspend', 'reactivate' actions, requiring reason only for 'reject'
- [x] Update `_processModeration` to set correct statuses for 'reject' (to 'rejected') and 'reactivate' (to 'active')
- [x] Adjust local state updates for new moderation statuses
