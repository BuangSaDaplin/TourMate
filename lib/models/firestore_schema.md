# Firestore Schema

## users/{uid}
- displayName: String
- email: String
- photoURL: String
- role: String [tourist|guide|admin]
- guide_verified: Boolean
- createdAt: Timestamp

## guides/{uid}
- idDocuments: Array<String> (Storage paths)
- lguCertificate: String (Storage path)
- verificationStatus: String [pending|approved|rejected]

## tours/{tourId}
- title: String
- description: String
- price: Number
- category: String
- maxParticipants: Number
- currentParticipants: Number
- startTime: Timestamp
- endTime: Timestamp
- meetingPoint: String
- media: Array<String> (Storage URLs)
- createdBy: String (UID)
- shared: Boolean
- itinerary: Array<Map<String, String>> [{time, activity, location}]
- status: String [published|suspended]

## bookings/{bookingId}
- tourId: String
- userId: String
- guideId: String
- type: String [private|shared]
- participantsCount: Number
- totalPrice: Number
- status: String [pending|confirmed|cancelled|completed]
- createdAt: Timestamp

## payments/{paymentId}
- bookingId: String
- userId: String
- amount: Number
- status: String [mock_pending|completed|refunded]
- createdAt: Timestamp

## chats/{chatRoomId}/messages/{messageId}
- senderId: String
- text: String
- mediaUrl: String
- timestamp: Timestamp

## reviews/{reviewId}
- tourId: String
- userId: String
- rating: Number (1-5)
- text: String
- createdAt: Timestamp
- moderated: Boolean
