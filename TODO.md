# TODO: Implement Conversation List Behavior and Chat Blocking Feature

## Tasks
- [x] Modify DatabaseService.getUserChatRooms() to display all conversations regardless of status
- [x] Add blockedBy field to ChatRoomModel to track who initiated the block
- [x] Implement block functionality in chat_screen.dart
- [x] Update chat_screen UI to handle blocked state (disable input, show notices)
- [x] Test the implementation

## Details
- Remove status filter in getUserChatRooms() to show active, archived, and blocked conversations
- Add blockedBy field to ChatRoomModel and update serialization methods
- In chat_screen, implement _blockConversation() to set status to blocked and blockedBy to current user
- Add UI logic: when blocked, disable message input and show appropriate notice based on blocker and blocked user's roles
