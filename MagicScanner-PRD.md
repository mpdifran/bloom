# Magic Scanner PRD

**Feature Name:** Magic Scanner
**Location:** `Apps/Bloom/Bloom/UserInterface/Actions/FoodTracking/MagicScanner`
**Status:** Ready for Implementation
**Last Updated:** 2025-10-25
**Version:** 1.0

---

## Overview

Magic Scanner is an asynchronous AI-powered food scanning experience that allows users to quickly capture food photos and receive AI-generated nutrition information without waiting for processing to complete. This feature addresses timeout issues with the current synchronous food scanning endpoint while providing a seamless, fast capture experience.

### Goals

1. **Instant Capture**: Enable users to snap and save food photos immediately without waiting for AI processing
2. **Solve Timeout Issues**: Move AI processing to an asynchronous background task to eliminate timeout failures
3. **Reliable Results Delivery**: Use push notifications + polling to ensure users always receive their results
4. **Improved UX**: Provide clear visual feedback about processing status in the nutrition view

---

## Design Decisions

All open questions have been resolved. Here are the key decisions that shape this feature:

### Core Behavior
- **Deletion**: When a user deletes a processing item, immediately cancel the backend processing job to save resources
- **Cancellation**: No separate "cancel" button - users can only delete the entire item
- **Processing Timeout**: No timeout - processing continues until success or failure
- **Context Editing**: Context text is locked after save (cannot be edited)

### Data & Storage
- **Results Storage**: Use **both** Redis (primary) and in-memory store (backup) for redundancy
  - Both have 48-hour cleanup policy
  - If one fails, the other can serve results
- **Database Persistence**: Redis + in-memory only - no PostgreSQL persistence of results
- **Image Retention**: Keep uploaded images for 48 hours (same as results), then cleanup
- **Image Size**: Match existing AI food scanner image size limits

### User Experience
- **Processing UI**: Show processing items **inline by timestamp** in nutrition view (not in special section)
- **Results Animation**: **Pulse/highlight** the item briefly when results arrive to draw attention
- **Time Estimates**: No time estimates - just show spinner with "Processing..." text
- **Notifications**: **No local notification** when results are ready (silent update only)
- **Error Display**: Show specific error message with **"Retry" button** on failures
- **Concurrent Limit**: **No limit** on simultaneous processing items

### Camera Features
- **Meal Type Selector**: Quick breakfast/lunch/dinner/snack picker before capture
- **Gallery Access**: Allow selecting existing photos from library in addition to camera capture
- **Image Cropping**: Always enforce **square crop (1:1 aspect ratio)** for consistency

### Multi-Device Behavior
- **Processing State Sync**: Only the uploading device shows processing state
- Other devices don't see the item until processing completes and it syncs as a regular food log

### Telemetry
- Track **core journey events**: scan_started, photo_captured, item_saved, processing_completed, results_viewed, item_deleted
- Track **upload-to-results time**: Measure end-to-end duration from backend upload to client receiving results

---

## User Flow

### 1. Photo Capture
- User opens Magic Scanner from the food tracking actions
- Full-screen camera view appears with:
  - Camera preview (similar to default iOS Camera app)
  - **Quick meal type selector** (Breakfast/Lunch/Dinner/Snack)
  - **Gallery access button** to select existing photos from library
  - Capture button, flash toggle, camera flip controls
- User either takes a new photo OR selects from gallery

### 2. Review & Context
- App displays a `CardView` overlay containing:
  - The captured image (automatically cropped to square 1:1 aspect ratio)
  - Selected meal type (pre-filled, editable)
  - A text field for adding optional context (e.g., "grilled chicken breast, no sauce")
  - "Save" button and "Retake" button

### 3. Immediate Save
- When user taps "Save":
  - Create a partial food item record in SwiftData immediately
  - Assign an `AIFoodProcessingIdentifier` to track this item
  - Store the processing state as "in progress"
  - Close the Magic Scanner view

### 4. Processing Indicator
- The food item appears in the Nutrition view immediately
- Item is shown **inline by timestamp** (same position as completed food logs)
- Visual indicator shows processing state: spinner + "Processing..." text
- User can continue using the app normally

### 5. Results Delivery
- Backend completes AI processing (stored in both Redis and in-memory cache)
- Silent push notification sent to device with the `AIFoodProcessingIdentifier`
- Client fetches results from Redis/in-memory cache
- Food item **pulses/highlights briefly** to draw attention
- Full nutrition information appears, processing indicator removed
- **No local notification** is shown (silent update only)

### 6. Bulk Fetch (Fallback)
- When app comes to foreground:
  - Client checks for any items still marked as "processing"
  - Sends bulk request for all pending `AIFoodProcessingIdentifier`s
  - Updates any items that have completed processing
  - This handles cases where silent push notifications failed

---

## Technical Architecture

### Client-Side Components

#### Data Models

**AIFoodProcessingIdentifier**
```swift
public struct AIFoodProcessingIdentifier: Identifier {
  public let rawValue: String

  public init() {
    self.rawValue = "ai_food_\(UUID().uuidString)"
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
```

**MagicScannerFoodItem (SwiftData Model)**
- `id: String` - SwiftData persistent identifier
- `processingIdentifier: String` - The AIFoodProcessingIdentifier
- `imageData: Data` - The captured photo (square cropped to 1:1)
- `contextText: String?` - User-provided context (locked after save)
- `mealType: MealType` - Breakfast/Lunch/Dinner/Snack (selected during capture)
- `processingState: ProcessingState` - Enum: `.pending`, `.processing`, `.completed`, `.failed`
- `createdAt: Date` - When the photo was taken
- `completedAt: Date?` - When processing finished
- `foodItemServings: [FoodItemServing]?` - Populated after processing completes
- `errorMessage: String?` - If processing failed

#### Views

**MagicScannerCameraView**
- Full-screen camera interface (similar to iOS Camera app)
- **Quick meal type selector** (segmented control or button bar)
- **Gallery access button** for selecting existing photos
- Capture button (center, prominent)
- Flash toggle and camera flip controls

**MagicScannerReviewCardView**
- Card overlay with captured image (enforced square 1:1 crop)
- Meal type selector (pre-filled, can be changed)
- Multi-line text field for optional context
- "Save" button (primary action)
- "Retake" button (secondary action)

**NutritionMagicScannerCell**
- Custom cell for processing items shown inline by timestamp
- Displays square image thumbnail + spinner + "Processing..." text
- **Shows retry button if processing failed** (with error message)
- **Pulses/highlights when results arrive** to draw attention
- Tap to view details or delete

#### Managers

**MagicScannerManager**
- Coordinates the scanning flow
- Handles image capture from camera or gallery
- Enforces square 1:1 crop on all images
- Creates SwiftData records with meal type
- Triggers backend requests with upload
- Processes silent push notifications
- Handles bulk fetching on app foreground
- **Sends cancellation request when user deletes processing item**
- Handles retry logic for failed processing

### Backend Components

#### New API Endpoint

**POST /food/magic-scan**

Request:
```json
{
  "processingIdentifier": "ai_food_abc-123-def",
  "imageFileID": "file_xyz789",
  "contextText": "grilled chicken breast, no sauce"
}
```

Response (immediate):
```json
{
  "processingIdentifier": "ai_food_abc-123-def",
  "status": "queued",
  "estimatedSeconds": 30
}
```

**Background Processing:**
1. Endpoint returns immediately after queuing the task
2. Background worker processes the image using existing AI logic
3. Results are cached in **both Redis and in-memory store** for redundancy
4. Both caches use the `AIFoodProcessingIdentifier` as key with 48-hour TTL
5. Silent push notification sent to user's device

**POST /food/magic-scan/cancel**

Request:
```json
{
  "processingIdentifier": "ai_food_abc-123-def"
}
```

Response:
```json
{
  "processingIdentifier": "ai_food_abc-123-def",
  "cancelled": true
}
```

Called when user deletes a processing item. Cancels the background job and clears caches.

#### Results Cache Structure (Redis + In-Memory)

**Key:** `magic_scanner:{AIFoodProcessingIdentifier}`
**TTL:** 48 hours (both Redis and in-memory)
**Value:**
```json
{
  "processingIdentifier": "ai_food_abc-123-def",
  "status": "completed",
  "foodItems": [
    {
      "name": "Grilled Chicken Breast",
      "servingSize": "100g",
      "calories": 165,
      "protein": 31,
      "carbs": 0,
      "fat": 3.6,
      // ... other nutrition data
    }
  ],
  "completedAt": "2025-10-25T14:30:00Z"
}
```

If processing fails:
```json
{
  "processingIdentifier": "ai_food_abc-123-def",
  "status": "failed",
  "errorMessage": "Unable to identify food in image",
  "completedAt": "2025-10-25T14:30:00Z"
}
```

#### Fetch Results Endpoint

**POST /food/magic-scan/results**

Request (single):
```json
{
  "processingIdentifier": "ai_food_abc-123-def"
}
```

Request (bulk):
```json
{
  "processingIdentifiers": [
    "ai_food_abc-123-def",
    "ai_food_xyz-456-ghi"
  ]
}
```

Response:
```json
{
  "results": [
    {
      "processingIdentifier": "ai_food_abc-123-def",
      "status": "completed",
      "foodItems": [...],
      "completedAt": "2025-10-25T14:30:00Z"
    },
    {
      "processingIdentifier": "ai_food_xyz-456-ghi",
      "status": "processing",
      "estimatedSecondsRemaining": 15
    }
  ]
}
```

**Cache Miss Behavior:**
- If Redis does not contain result, check in-memory store as fallback
- If neither cache has result, automatically kick off new AI processing task
- Returns `status: "processing"` to the client
- Client can poll or wait for push notification
- This ensures results are regenerated if both caches expire or fail

---

## Push Notifications

### Silent Push Notification

When processing completes, send a silent push notification:

**Payload:**
```json
{
  "aps": {
    "content-available": 1
  },
  "type": "magic_scanner_complete",
  "processingIdentifier": "ai_food_abc-123-def"
}
```

**Client Handling:**
1. App receives silent push in background
2. Fetches results using the `processingIdentifier` from Redis or in-memory cache
3. Updates SwiftData record with full nutrition data
4. Triggers pulse/highlight animation if user is viewing nutrition screen
5. **No local notification shown** - update is silent

---

## Error Handling & Edge Cases

### Timeout Prevention
- Primary goal achieved by making processing asynchronous
- Client never waits on the network call for AI processing

### Failed Processing
- Store specific error message in SwiftData record
- Show error state in Nutrition view with **"Retry" button**
- Retry button re-uploads the same image and context with new processing identifier
- User can also delete the failed item entirely

### User Deletion During Processing
- When user deletes a processing item:
  - Client immediately sends cancellation request to backend
  - Backend cancels the job and clears Redis/in-memory caches
  - SwiftData record is deleted locally
- Saves compute resources and storage for abandoned scans

### Cache Expiration (48 hours)
- Both Redis and in-memory caches expire after 48 hours
- If client tries to fetch after expiration:
  - Endpoint automatically triggers re-processing
  - New push notification sent when complete
- This handles edge cases of very old scans

### Silent Push Notification Failure
- Bulk fetch on app foreground catches any missed updates
- Ensures eventual consistency

### Network Failure on Initial Request
- Retry logic in `MagicScannerManager`
- Store locally and attempt upload when network available
- Show "waiting to upload" state

### Duplicate Processing Prevention
- Backend checks if `processingIdentifier` exists in Redis or in-memory store
- If exists and still valid, return cached result immediately
- Prevents redundant processing for the same item

### Storage Redundancy (Redis + In-Memory)
- If Redis fails, in-memory store serves as backup
- If in-memory fails, Redis serves results
- If both fail on fetch, automatic re-processing kicks off
- 48-hour cleanup runs on both stores independently

---

## Database Migrations

### SwiftData Schema

Need to add new model `MagicScannerFoodItem` to DataContainer:

```swift
@Model
final class MagicScannerFoodItem {
  @Attribute(.unique) var id: String
  var processingIdentifier: String
  @Attribute(.externalStorage) var imageData: Data // Square 1:1 cropped
  var contextText: String? // Locked after save
  var mealType: MealType // Breakfast/Lunch/Dinner/Snack
  var processingState: ProcessingState
  var createdAt: Date
  var completedAt: Date?
  var errorMessage: String?

  // Relationships
  var foodItemServings: [FoodItemServing]?

  enum ProcessingState: String, Codable {
    case pending
    case processing
    case completed
    case failed
  }
}
```

### Backend Database

**magic_scanner_requests table:**
- `id` - UUID primary key
- `processing_identifier` - Unique string (indexed)
- `user_id` - Foreign key to users
- `image_file_id` - Reference to uploaded image (stored for 48 hours)
- `context_text` - Optional text (nullable)
- `meal_type` - Enum: breakfast, lunch, dinner, snack
- `status` - Enum: pending, processing, completed, failed, cancelled
- `created_at` - Timestamp
- `completed_at` - Timestamp (nullable)
- `error_message` - Text (nullable)
- `cancelled_at` - Timestamp (nullable)

---

## Success Metrics

### Core Journey Events (TelemetryDeck)
Track these key user actions:
- `magic_scanner_opened` - User opened Magic Scanner
- `magic_scanner_photo_captured` - Photo taken or selected from gallery
- `magic_scanner_item_saved` - User saved item with context
- `magic_scanner_processing_completed` - Backend finished processing
- `magic_scanner_results_viewed` - User viewed completed results
- `magic_scanner_item_deleted` - User deleted processing or completed item
- `magic_scanner_retry_tapped` - User retried failed scan

### Performance Metrics
- **Upload-to-Results Time**: Measure duration from backend upload to client receiving results
  - Start timer when upload begins
  - End timer when silent push received OR bulk fetch returns results
  - Track p50, p95, p99 durations
- **Time to Save**: Time from photo capture to save confirmation (target: <1 second)
- **AI Processing Time**: Background processing duration (target: <30 seconds p95)
- **Push Delivery Rate**: % of silent pushes successfully delivered vs bulk fetch fallback

### User Experience Metrics
- **Adoption Rate**: % of users who use Magic Scanner vs legacy scanner
- **Completion Rate**: % of scans that successfully return results
- **Retry Rate**: % of scans that require retry due to errors
- **Cancellation Rate**: % of items deleted before processing completes
- **Gallery vs Camera**: % of users selecting existing photos vs taking new photos

### Reliability Metrics
- **Timeout Reduction**: Compare timeout rates vs legacy endpoint (target: 95% reduction)
- **Cache Hit Rate**: % of fetch requests finding results in Redis or in-memory
- **Failed Processing Rate**: % of scans that fail AI processing
- **Storage Failover Rate**: How often in-memory cache serves when Redis fails

---

## Implementation Phases

### Phase 1: Core Client Implementation
- [ ] Create `AIFoodProcessingIdentifier` type in BloomModel
- [ ] Add SwiftData model `MagicScannerFoodItem` with mealType field
- [ ] Build `MagicScannerCameraView` with meal selector and gallery access
- [ ] Implement square 1:1 image cropping logic
- [ ] Build `MagicScannerReviewCardView` with meal type picker
- [ ] Implement `MagicScannerManager` coordinator
- [ ] Add processing state UI in Nutrition view (inline display)
- [ ] Implement pulse/highlight animation for completed items

### Phase 2: Backend Infrastructure
- [ ] Create database table and migrations (including meal_type, cancelled_at)
- [ ] Set up **both Redis and in-memory caching** with 48h TTL
- [ ] Implement `/food/magic-scan` endpoint (returns immediately)
- [ ] Implement `/food/magic-scan/cancel` endpoint
- [ ] Set up background job queue for AI processing
- [ ] Add silent push notification sending on completion

### Phase 3: Results Fetching & Error Handling
- [ ] Implement `/food/magic-scan/results` endpoint (single + bulk)
- [ ] Add Redis → in-memory fallback logic
- [ ] Handle silent push notifications on client
- [ ] Implement bulk fetch on app foreground
- [ ] Add retry button UI and logic for failed items
- [ ] Implement deletion cancellation flow
- [ ] Add auto-regeneration on cache miss

### Phase 4: Telemetry & Testing
- [ ] Add all core journey telemetry events
- [ ] Implement upload-to-results time measurement
- [ ] Test timeout scenarios (should never occur)
- [ ] Test push notification delivery and bulk fetch fallback
- [ ] Test cache expiration and regeneration
- [ ] Test Redis failure → in-memory fallback
- [ ] Test deletion during processing (cancellation)
- [ ] Add user-facing error messages

### Phase 5: Launch
- [ ] A/B test vs legacy scanner
- [ ] Monitor success metrics
- [ ] Gather user feedback
- [ ] Iterate based on data

---

## Dependencies

### Client Dependencies
- SwiftData for local persistence
- HealthKit for nutrition data (existing)
- AVFoundation for camera capture
- PhotosUI/PHPickerViewController for gallery access
- UserNotifications for silent push handling (existing)
- CoreGraphics/UIKit for square 1:1 image cropping

### Backend Dependencies
- **Redis** for primary result caching (48h TTL)
- **In-memory store** for backup result caching (48h TTL)
- Background job queue (Vapor Queues or similar)
- Push notification service (APNs)
- Image storage service with 48h retention (existing)
- AI/ML food recognition service (existing)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Push notifications fail frequently | High | **Implemented**: Bulk fetch on foreground as fallback |
| Redis becomes unavailable | High | **Implemented**: In-memory store serves as backup + auto-regeneration |
| AI processing takes too long | Medium | **Accepted**: No timeout, processing continues indefinitely with spinner |
| Users lose internet after capture | Medium | **Implemented**: Queue uploads, retry when online, show "waiting to upload" |
| Image storage costs increase | Medium | **Mitigated**: 48h automatic cleanup + match existing scanner size limits |
| Multiple devices sync issues | Low | **Accepted**: Only uploading device shows processing state |
| Users abandon many scans | Medium | **Implemented**: Cancellation on delete clears jobs and saves resources |
| Both Redis and in-memory fail | Low | **Implemented**: Auto-regeneration triggered, new push sent on completion |

---

## Future Enhancements

Post-v1 features to consider:

1. **Batch Scanning**: Allow multiple photos in one session before uploading
2. **Smart Cropping**: Auto-detect food regions and suggest optimal crop
3. **Recipe Recognition**: Identify complete multi-course meals from single photo
4. **History & Favorites**: Quick re-log from Magic Scanner history
5. **Voice Context**: Allow voice input for context instead of typing
6. **Real-time Preview**: Show confidence scores as user captures (on-device ML)
7. **Offline Processing**: Use on-device ML model for instant results
8. **Edit Context After Save**: Allow editing with re-processing
9. **Progress Percentage**: Show more granular progress than just spinner
10. **Cross-Device Sync**: Show processing items on all devices

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Codebase architecture patterns
- [CLAUDE.md](CLAUDE.md) - Development guidelines
- Existing AI Food Scanner implementation: `Apps/Bloom/Bloom/UserInterface/Actions/FoodTracking/AIFoodScanner`
- Nutrition tracking: `Apps/Bloom/Bloom/UserInterface/Nutrition`
- Network layer: `Apps/Bloom/CoreNetwork`
