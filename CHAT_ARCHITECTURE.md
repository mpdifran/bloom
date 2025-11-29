# Chat System Architecture

This document provides a comprehensive overview of Bloom's chat system architecture, covering data models, flow patterns, error handling, and breaking change considerations.

## Table of Contents

- [Overview](#overview)
- [Data Models](#data-models)
- [Data Flow](#data-flow)
- [Architecture Patterns](#architecture-patterns)
- [UI Components](#ui-components)
- [Error Handling](#error-handling)
- [File Storage](#file-storage)
- [Backend Integration](#backend-integration)
- [Breaking Changes](#breaking-changes)
- [Key Implementation Details](#key-implementation-details)

---

## Overview

The Bloom chat system is a sophisticated, production-ready architecture that enables real-time AI-powered health conversations with:

- **Streaming responses** for smooth UX
- **Rich content support** (goals, food logs, reminders, workouts, vital tracking)
- **Deep health integration** via OpenAI tool calling to query HealthKit data
- **Multi-device sync** via CloudKit
- **Dual-version protocol** (V1 legacy single-conversation, V2 multi-conversation)
- **Resilient state management** with Redis and in-memory fallback
- **WebSocket-first** communication with APNs fallback
- **Auto-logging** of health actions from AI responses

---

## Data Models

### SwiftData Models (Client-side Persistence)

#### ChatMessage (V28)
**Location:** `Apps/Bloom/DataContainer/SwiftData/Schema/V28/ChatMessageV28.swift`

The core message model supporting text, images, and rich content:

```swift
@Model
final class ChatMessage {
    var id: String                    // Unique identifier
    var isCurrentUser: Bool            // User vs assistant message
    var date: Date                     // Message timestamp
    var message: String?               // Text content (optional)
    var richContent: Data?             // Encoded rich content (goals, food logs, etc.)
    var imageData: Data?               // Image attachments (@Attribute(.externalStorage))
    var dbID: String?                  // Reference to health data record (e.g., HK sample UUID)
    var hasPerformedAction: Bool       // Tracks if rich content action was executed
    var responseID: String?            // OpenAI response ID for grouping
    var requestID: String?             // Request ID for tracking request/response pairs
    var conversation: ChatConversation? // Parent conversation relationship
}
```

**Key Points:**
- All properties optional or have defaults (CloudKit requirement)
- Images stored externally via `@Attribute(.externalStorage)` for efficient SQLite performance
- `dbID` links messages to HealthKit samples or other health records
- `hasPerformedAction` prevents duplicate auto-logging of health data

#### ChatConversation (V28)
**Location:** `Apps/Bloom/DataContainer/SwiftData/Schema/V28/ChatConversationV28.swift`

Manages conversation metadata and message relationships:

```swift
@Model
final class ChatConversation {
    var id: String                     // Unique identifier (UUID)
    var name: String                   // Conversation title (AI-generated)
    var lastMessageID: String?         // Tracks last message for context window
    var createdDate: Date              // Creation timestamp
    var updatedAt: Date                // Last update time (used for sorting)
    var isPinned: Bool                 // Pin to top of list
    var messages: [ChatMessage]?       // One-to-many relationship with cascade delete
}
```

**Key Points:**
- `lastMessageID` enables V2 clients to maintain conversation context with OpenAI
- `updatedAt` modified on every new message for proper sorting
- Cascade delete ensures messages are removed when conversation deleted
- CloudKit sync enabled for cross-device conversations

### Shared Models (Client-Server Communication)

**Location:** `Shared/BloomModel/Sources/BloomModel/Chat/SocketMessage/`

The `SocketMessage` namespace contains 13 message types for WebSocket communication:

#### Request Types (Client → Server)

1. **MessageRequest** - User sends message to server
   - `text: String` - User's message
   - `imageFileIDs: [String]?` - OpenAI file IDs for images
   - `userInfo: String?` - Health context JSON
   - `extraSystemContext: String?` - Context from Today View
   - `requestID: String` - Unique request identifier
   - `lastMessageID: String?` - Previous response ID (V2 only)
   - `conversationID: String?` - Conversation identifier (V2 only)

2. **ToolCallsResponse** - Client responds with health data
   - `outputs: [ToolOutput]` - Query results
   - `conversationID: String?` - Conversation identifier

#### Response Types (Server → Client)

3. **MessageChunkResponse** - Streaming text chunks
   - `chunk: String` - Partial message content
   - `conversationID: String?`

4. **MessageResponse** - Complete text message
   - `message: String` - Full message content
   - `responseID: String` - OpenAI response ID
   - `conversationID: String?`

5. **RichMessageResponse** - Rich content actions
   - `kind: RichMessageKind` - Type of rich content
   - `content: Data` - Encoded content
   - `conversationID: String?`
   - `isPermanent: Bool` - Auto-execute and save vs temporary display

6. **ToolCallsRequest** - Server requests health data
   - `id: String` - Tool call ID
   - `queries: [HealthQuery]` - Array of health data queries
   - `conversationID: String?`

7. **TypingIndicator** - Assistant typing status
   - `isTyping: Bool`
   - `statusText: String?` - Optional status message
   - `conversationID: String?`

8. **ResponseCompleted** - Signal that AI response is finished
   - `lastMessageID: String` - For V2 context tracking
   - `conversationID: String?`

9. **ConversationNameUpdate** - Auto-generated conversation title
   - `name: String`
   - `conversationID: String`

10. **Error** - Error messages
    - `message: String`
    - `conversationID: String?`

#### Specialized Messages

11. **Quantity** - Health metric quantities (tool call results)
12. **UserFacts** - User facts create/delete
13. **Reminders** - Reminder create/delete

#### Rich Content Types

Rich messages support these action types:
- `newGoals` - Health goals
- `detectedFood` - Detected food from images
- `logWeight` - Weight logging
- `logPeriod` - Period tracking
- `logWater` - Water intake
- `logBloodPressure` - Blood pressure
- `logBowelMovement` - Bowel movement tracking
- `createWorkout` - Workout plan creation
- `createReminder` - Reminder creation
- `deleteReminder` - Reminder deletion
- `createUserFacts` - User facts creation
- `deleteUserFacts` - User facts deletion

### Data Transfer Objects (DTOs)

**ChatMessageDTO** - Immutable, Sendable representation for cross-actor communication
**Location:** `Apps/Bloom/DataContainer/DTOs/ChatMessageDTO.swift`

```swift
struct ChatMessageDTO: Sendable {
    let id: PersistentIdentifier
    let isCurrentUser: Bool
    let date: Date
    let content: Content

    enum Content: Sendable {
        case message(String)
        case imageData(Data)
        case richContent(Data)
    }
}
```

**ChatConversationDTO** - Immutable, Sendable conversation representation
**Location:** `Apps/Bloom/DataContainer/DTOs/ChatConversationDTO.swift`

---

## Data Flow

### Client → Server Flow

#### 1. User Input (ChatViewModel)
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatViewModel.swift:120`

- User types message or uploads image
- Can include "chat contexts" (insights from Today View)
- Image resized to 800px width, JPEG 75% quality

#### 2. Pre-Processing (ChatController.send)
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:180`

```swift
func send(
    _ text: String,
    image: UIImage?,
    context: ChatContext?,
    conversation: ChatConversation
) async throws
```

Steps:
1. Generate unique `requestID` (format: "request_UUID")
2. Create/fetch conversation via ConversationModelActor
3. Save user message to SwiftData immediately
4. Save image message separately (if provided)
5. Save context message as rich content (if provided)

#### 3. Health Context Generation (ChatVitalConverter)
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatVitalConverter.swift`

Generates health context for AI:
- Demographics (age, sex, height, weight)
- Current date/time
- Encoded as JSON string (`HealthVitalData.ChatContext`)

#### 4. Image Upload (if applicable)
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:250`

- POST to `/v1/chat/upload-image`
- Backend uploads to OpenAI Files API
- Returns array of `fileIDs`

#### 5. WebSocket Message Construction
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:280`

Create `SocketMessage.MessageRequest`:
```swift
let request = SocketMessage.MessageRequest(
    text: text,
    imageFileIDs: fileIDs,
    userInfo: healthContext,
    extraSystemContext: context?.systemContext,
    requestID: requestID,
    lastMessageID: conversation.lastMessageID,  // V2 only
    conversationID: conversation.id              // V2 only
)
```

#### 6. Send via WebSocket
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:300`

- Encode to JSON via `JSONEncoder.bloomModel`
- Send as binary data over WebSocket
- Play send sound
- Start telemetry timers (TTFT - Time To First Token, TTFTC - Time To First Token Chunk)

### Server Processing

#### WebSocket Handler (WebSocketService)
**Location:** `Backend/Bloom-Backend/Sources/App/Services/WebSocket/WebSocketService.swift`

- Registers socket for user ID: `[UserIdentifier: WebSocket]`
- Handles ping/pong for connection health (20s interval)
- Flushes cached streaming content on reconnect
- Routes messages to ChatService

#### Chat Service Processing (ChatService.on)
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:120`

1. Store requestID in RequestIDTracker (prevents duplicate processing)
2. Build OpenAI input messages:
   - System message with user context
   - Optional extra system context (from Today View)
   - User message with images
3. Generate conversation title (async, first message only)
4. Stream response from OpenAI

#### Streaming Response (ChatService.streamResponse)
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:200`

```swift
func streamResponse(
    userID: UserIdentifier,
    input: [OpenAI.Response.Input],
    conversationID: String?,
    previousResponseID: String?
) async throws
```

Steps:
1. Fetch previous responseID (from Redis for V1, client-provided for V2)
2. Fortify inputs (inject error outputs for pending tool calls)
3. Create OpenAI streaming request:
   - Model: `o4-mini` (default) or override
   - Instructions: Chat assistant prompt
   - Tools: `queryUserHealthData` function
   - Reasoning: Low effort, auto summary
4. Process stream events:
   - `created` - Reset buffers, store response ID
   - `inProgress` - Send typing indicator
   - `outputTextDelta` - Buffer and parse chunks/JSON
   - `outputTextDone` - Send complete messages
   - `outputItemDone` - Handle tool calls
   - `completed` - Store last response ID, send completion signal
   - `failed`/`error` - Retry once

#### JSON Buffering (StreamJSONBuffer)
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/StreamJSONBuffer.swift`

- Detects JSON blocks in markdown code fences
- Separates text from JSON during streaming
- Emits chunks or complete JSON objects
- Pattern: ` ```json\n{...}\n``` `

### Server → Client Flow

#### Message Reception (WebSocketHandle)
**Location:** `Apps/Bloom/Bloom/Network/WebSocket/WebSocketHandle.swift:150`

Receives messages as binary/text data, decodes SocketMessage types:

#### 1. MessageChunkResponse (Streaming)
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:400`

- Append chunk to in-progress message buffer
- Throttled updates (100ms intervals)
- Turn off typing indicator on first chunk
- Track TTFTC telemetry

#### 2. MessageResponse (Complete)
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:450`

- Save to SwiftData via ChatMessageModelActor
- Clear in-progress messages
- Update conversation `updatedAt`
- Store `responseID` on message

#### 3. RichMessageResponse (Actions)
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:500`

**Temporary (isPermanent: false):**
- Show in UI, don't save to SwiftData
- User can manually execute action

**Permanent (isPermanent: true):**
- Auto-execute action immediately
- Save to SwiftData with `dbID` reference
- Mark `hasPerformedAction: true`
- Actions include: saving to HealthKit, creating reminders, etc.

#### 4. ToolCallsRequest (Health Queries)
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:600`

- Client performs HealthKit queries via CoreHealth
- Returns results via ToolCallsResponse
- Queries run in parallel task group
- Show status text: "Reading nutrition data...", "Reading workout data...", etc.

#### 5. TypingIndicator
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:700`

- Update `assistantIsTyping[conversationID]`
- Update `assistantTypingStatus[conversationID]` with status text
- UI shows animated typing indicator

#### 6. ResponseCompleted
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:750`

- Mark `conversationInProgress[conversationID] = false`
- Update `lastMessageID` in SwiftData
- Clear request tracking
- Track TTFT telemetry

#### 7. ConversationNameUpdate
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:800`

- Update conversation name in SwiftData
- Generated by OpenAI on first message

#### 8. Error
**Handler:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:850`

- Set global error state
- Mark conversation not in progress
- Report to TelemetryDeck

### WebSocket Communication Patterns

#### Connection Management
**Location:** `Apps/Bloom/Bloom/Network/WebSocket/WebSocketHandle.swift`

- Actor-isolated `WebSocketHandle`
- Automatic reconnection on disconnection
- Ping every 20 seconds
- Background observation tasks for:
  - Data reception
  - Disconnection events
  - Error handling
- Clean shutdown with normal closure code

#### Message Encoding
- All messages use `JSONEncoder.bloomModel`
- Sent as binary data (not text)
- Received as both binary and text (converted to data)

#### Fallback to APNs
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:900`

If WebSocket disconnected:
- Server sends via push notifications
- **Alert notifications** for text messages (user sees notification)
- **Background notifications** for tool calls/rich content (silent processing)
- 1-hour expiration on queued content

---

## Architecture Patterns

### ViewModels

#### Structure
- Suffix with `ViewModel`
- Use `@Observable` macro for SwiftUI integration
- `@MainActor` isolated
- Manage UI state and coordinate with actors

#### Example: ChatViewModel
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatViewModel.swift`

```swift
@Observable @MainActor
final class ChatViewModel {
    // UI State
    var cellModels = [ChatCellModel]()
    var error: Error?
    var conversationInProgress = false
    var shouldTriggerScroll = false

    // Dependencies
    private let conversationActor: ConversationModelActor
    private let historyModifier: ChatHistoryModifier
    private let conversationID: String

    // Observation
    private var chatControllerTask: Task<Void, Never>?
    private var historyModifierTask: Task<Void, Never>?
}
```

**Responsibilities:**
- Expose UI state to SwiftUI/UIKit views
- Handle user interactions (send message, attach image)
- Observe actor state changes via AsyncStream
- Transform actor data for UI consumption
- Error handling and presentation

### Actor Usage

#### Thread-Safe Data Access

**1. ChatController (Singleton)**
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift`

Global chat state management:
```swift
@MainActor
final class ChatController {
    @AsyncStreamable var assistantTypingStatus: [String: String?] = [:]
    @AsyncStreamable var assistantIsTyping: [String: Bool] = [:]
    @AsyncStreamable var inProgressMessages: [String: [InProgressMessage]] = [:]
    @AsyncStreamable var conversationInProgress: [String: Bool] = [:]
    @AsyncStreamable var error: Error?
}
```

Responsibilities:
- WebSocket lifecycle management
- Message sending
- Request/response ID tracking
- Tool call tracking
- In-progress message buffering (all conversations)
- Typing status (all conversations)

**2. ChatHistoryModifier (Per-conversation Actor)**
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatHistoryModifier.swift`

Per-conversation message management:
```swift
actor ChatHistoryModifier {
    @AsyncStreamable var cellModels: [ChatCellModel] = []

    private let conversationID: String
    private let messageActor: ChatMessageModelActor
    private var loadedMessages: [ChatMessageDTO] = []
}
```

Responsibilities:
- Load last 30 messages from SwiftData
- Subscribe to ChatController updates
- Build `ChatCellModel` array:
  - Completed messages from SwiftData
  - In-progress streaming messages
  - Status text (e.g., "Reading nutrition data...")
  - Typing indicator
  - Prompts (empty state)
- Process rich content asynchronously to avoid UI blocking

**3. ChatMessageModelActor (SharedModelActor)**
**Location:** `Apps/Bloom/DataContainer/ModelActors/ChatMessageModelActor.swift`

Thread-safe SwiftData operations:
```swift
actor ChatMessageModelActor: SharedModelActor {
    func fetchMessages(for conversationID: String, limit: Int) -> [ChatMessageDTO]
    func save(message: ChatMessageDTO) throws
    func delete(messageID: PersistentIdentifier) throws
}
```

**4. ConversationModelActor (ModelActor)**
**Location:** `Apps/Bloom/DataContainer/ModelActors/ConversationModelActor.swift`

Conversation CRUD operations:
```swift
actor ConversationModelActor: ModelActor {
    func createConversation() -> ChatConversationDTO
    func updateLastMessageID(_ id: String, for conversationID: String)
    func updateName(_ name: String, for conversationID: String)
}
```

#### @AsyncStreamable Pattern
**Location:** `Apps/Bloom/BloomFoundation/Sources/BloomFoundation/PropertyWrappers/AsyncStreamable.swift`

Custom property wrapper for actor-safe observation:
```swift
@propertyWrapper
struct AsyncStreamable<Value> {
    private var value: Value
    private let continuation: AsyncStream<Value>.Continuation

    var projectedValue: AsyncStream<Value>
}
```

**Usage:**
```swift
actor ChatController {
    @AsyncStreamable var error: Error?
}

// Observe from MainActor
Task {
    for await error in chatController.$error {
        self.error = error
    }
}
```

### Concurrency Patterns

#### Strict Concurrency (Swift 6)
- Complete concurrency checking enabled
- All models marked `Sendable`
- DTOs for cross-actor data transfer
- Actor isolation for mutable state
- `@MainActor` for UI code

#### Task Groups
**Parallel Execution:**

1. **Tool Call Execution**
   **Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:650`
   ```swift
   await withTaskGroup(of: ToolOutput.self) { group in
       for query in queries {
           group.addTask {
               await self.executeHealthQuery(query)
           }
       }
   }
   ```

2. **Rich Content Processing**
   **Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatHistoryModifier.swift:200`
   ```swift
   await withTaskGroup(of: ProcessedRichContent?.self) { group in
       for richContent in richContents {
           group.addTask {
               await self.process(richContent)
           }
       }
   }
   ```

#### Async Sequences
- WebSocket data streaming: `URLSessionWebSocketTask.AsyncSequence`
- OpenAI response streaming: `AsyncStream<OpenAI.Response.Event>`
- Actor state observation: `AsyncStream<Value>`

### State Management

#### Global State (ChatController)
- WebSocket connection status
- Request/response ID tracking
- Tool call tracking
- In-progress messages (all conversations)
- Typing status (all conversations)
- Error state

#### Conversation State (ChatHistoryModifier)
- Loaded messages (last 30)
- In-progress messages (filtered for conversation)
- Cell models (renderable UI state)
- Typing indicator

#### Local State (ViewModels)
- UI-specific state (scroll position, keyboard visibility)
- Error handling
- User interactions (text input, image selection)

---

## UI Components

### Main Views

#### ChatViewController (UIKit)
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatViewController.swift`

UIKit-based chat interface:
- `UICollectionView` with custom compositional layout (`ChatLayout`)
- Keyboard handling with animated adjustments
- Auto-scrolling to bottom on new messages
- Pull-to-refresh for loading older messages
- Integration with SwiftUI via `UIHostingController`

**Key Methods:**
- `viewDidLoad()` - Setup collection view and observers
- `scrollToBottom(animated:)` - Auto-scroll on new messages
- `keyboardWillShow(_:)` - Adjust content insets

#### ChatViewModel
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatViewModel.swift`

```swift
@Observable @MainActor
final class ChatViewModel {
    var cellModels: [ChatCellModel]
    var error: Error?
    var conversationInProgress: Bool
    var shouldTriggerScroll: Bool

    func sendMessage(_ text: String)
    func attachImage(_ image: UIImage)
    func attachContext(_ context: ChatContext)
}
```

**Observation Pattern:**
```swift
init(conversationID: String) {
    // Observe ChatController
    chatControllerTask = Task {
        for await error in ChatController.shared.$error {
            self.error = error
        }
    }

    // Observe ChatHistoryModifier
    historyModifierTask = Task {
        for await cellModels in historyModifier.$cellModels {
            self.cellModels = cellModels
            self.shouldTriggerScroll = true
        }
    }
}
```

### Collection View Cells

**15+ Custom Cell Types:**

1. `ChatMessageCollectionViewCell` - Text messages
2. `ChatImageCollectionViewCell` - Image messages
3. `ChatRichContentCollectionViewCell` - Rich content wrapper
4. `ChatProcessedRichContentCollectionViewCell` - Specific rich content types
5. `ChatTypingIndicatorCollectionViewCell` - Typing animation
6. `ChatStatusCollectionViewCell` - Status text ("Reading nutrition data...")
7. `ChatGoalsCollectionViewCell` - Health goals
8. `ChatDetectedFoodCollectionViewCell` - Detected food
9. `ChatLogWeightCollectionViewCell` - Weight logging
10. `ChatLogPeriodCollectionViewCell` - Period tracking
11. `ChatLogWaterCollectionViewCell` - Water intake
12. `ChatLogBloodPressureCollectionViewCell` - Blood pressure
13. `ChatLogBowelMovementCollectionViewCell` - Bowel movement
14. `ChatWorkoutCollectionViewCell` - Workout plans
15. `ChatReminderCollectionViewCell` - Reminders

### Message Rendering

#### ChatCellModel
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatCellModel.swift`

Immutable, Sendable, Hashable cell representation:
```swift
enum ChatCellModel: Sendable, Hashable, Differentiable {
    case text(
        id: String,
        text: String,
        isCurrentUser: Bool,
        date: Date,
        isInProgress: Bool
    )
    case image(
        id: String,
        imageData: Data,
        isCurrentUser: Bool,
        date: Date
    )
    case richContent(
        id: String,
        content: ProcessedRichContent,
        isCurrentUser: Bool,
        date: Date
    )
    case typingIndicator(id: String, status: String?)
    case statusText(id: String, text: String)
    case prompts(id: String, prompts: [String])
}
```

**Key Features:**
- Conforms to `Differentiable` for efficient updates (DifferenceKit)
- Pre-processed to avoid async loading in UI
- Includes all necessary data for rendering

#### ProcessedRichContent
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ProcessedRichContent.swift`

Pre-processed rich content to avoid async loading in cells:
```swift
enum ProcessedRichContent: Sendable, Hashable {
    case goals([HealthGoal])
    case detectedFood(DetectedFood)
    case logWeight(Weight)
    case logPeriod(PeriodDetails)
    case logWater(WaterIntake)
    case logBloodPressure(BloodPressure)
    case logBowelMovement(BowelMovement)
    case createWorkout(Workout)
    case createReminder(Reminder)
    case deleteReminder(reminderID: String)
    case unknown
}
```

### Input Handling

#### ChatMessageBar
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatMessageBar.swift`

SwiftUI view for message input:
- `TextView` with keyboard management
- Image attachment button (camera/photo library)
- Voice input button
- Context attachment display (from Today View)
- Auto-expands for multi-line text
- Send button (disabled when empty)

#### ChatContextCell
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatContextCell.swift`

Displays attached insights from Today View:
- Preview of context content
- User can remove before sending
- Sent as `extraSystemContext` in MessageRequest

---

## Error Handling

### Network Error Patterns

#### Client-Side Errors

**1. WebSocket Connection Failures**
**Location:** `Apps/Bloom/Bloom/Network/WebSocket/WebSocketHandle.swift:200`

```swift
for await error in socket.$error {
    // Log error but don't always surface to UI
    TelemetryDeck.errorEvent("websocket_error", error: error)
    // Automatic reconnection triggered
}
```

**Handling:**
- Logged with TelemetryDeck
- Automatic reconnection attempts
- Not always surfaced to user (graceful degradation)

**2. Message Send Failures**
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatViewModel.swift:150`

```swift
func sendMessage(_ text: String) {
    Task {
        do {
            try await chatController.send(text, ...)
        } catch {
            self.error = error
            TelemetryDeck.errorEvent("chat_send_failed", error: error)
        }
    }
}
```

**Handling:**
- Set to `ChatViewModel.error` (displays error banner)
- Reported to TelemetryDeck
- **Not retried automatically** - user must retry manually

**3. SwiftData Operation Failures**
**Location:** `Apps/Bloom/DataContainer/ModelActors/ChatMessageModelActor.swift:100`

```swift
func save(message: ChatMessageDTO) throws {
    do {
        // SwiftData save operation
    } catch {
        TelemetryDeck.errorEvent("chat_swiftdata_save_failed", error: error)
        throw error
    }
}
```

**Handling:**
- Errors propagated to ViewModel
- Logged with TelemetryDeck
- Display error to user

#### Server-Side Errors

**1. SocketMessage.Error**
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:800`

```swift
let errorMessage = SocketMessage.Error(
    message: "Failed to process request",
    conversationID: conversationID
)
await send(errorMessage, to: userID)
```

**Handling:**
- Sent to client as JSON
- Sets `conversationInProgress = false`
- Logged with TelemetryDeck
- Displayed in chat UI

**2. OpenAI Stream Failures**
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:400`

```swift
func streamResponse(...) async throws {
    do {
        // Process stream
    } catch {
        if !hasRetried {
            // Clear Redis state and retry once
            try await redisService.delete("chat_last_response_id:\(userID)")
            return try await streamResponse(..., hasRetried: true)
        } else {
            // Surface error to client
            throw error
        }
    }
}
```

**Retry Logic:**
- **Single retry** on stream failure
- Clear Redis state before retry (prevents state corruption)
- Second failure surfaces to client

**3. Tool Call Failures**
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:500`

```swift
// Client returns empty results on query failure
// Don't block AI response
let emptyOutput = ToolOutput(id: toolCallID, output: "[]")
```

**Handling:**
- Empty results returned (don't block AI)
- Error logged with TelemetryDeck
- AI continues with partial data

**4. Fortification System**
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:600`

Handles orphaned tool calls (tool requests without responses):
```swift
func fortifyInputs(
    _ inputs: [OpenAI.Response.Input],
    pendingToolCalls: Set<String>
) -> [OpenAI.Response.Input] {
    // Inject error outputs for pending tool calls
    // Prevents OpenAI from waiting indefinitely
}
```

### Error Presentation

#### UI Display
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatViewController.swift:300`

- `ChatViewModel.error` drives error banner
- Inline system messages (not fully implemented)
- TelemetryDeck tracks all errors for monitoring

#### Telemetry Events
- `chat_send_failed` - Message send failures
- `chat_swiftdata_save_failed` - Database errors
- `websocket_error` - Connection issues
- `chat_stream_failed` - OpenAI streaming errors
- `chat_tool_call_failed` - Health query failures

---

## File Storage

### Chat Images/Files

#### Local Storage (SwiftData)
**Location:** `Apps/Bloom/DataContainer/SwiftData/Schema/V28/ChatMessageV28.swift:20`

```swift
@Attribute(.externalStorage)
var imageData: Data?
```

**Key Points:**
- Stored externally from SQLite database for performance
- Binary data stored in separate files
- Automatic cleanup when message deleted
- No size limit (system-managed)

#### Remote Storage (OpenAI Files API)
**Location:** `Backend/Bloom-Backend/Sources/App/Controllers/Chat/ChatController.swift:50`

```swift
func uploadImage(req: Request) async throws -> [String] {
    // 1. Receive image from client
    let imageData = try req.content.decode(ImageUpload.self)

    // 2. Upload to OpenAI Files API
    let fileID = try await openAIService.uploadFile(
        data: imageData,
        purpose: .vision
    )

    // 3. Return fileID array
    return [fileID]
}
```

**Storage Details:**
- Images uploaded to OpenAI Files API
- Returns `fileID` array
- Files referenced in `MessageRequest.imageFileIDs`
- OpenAI manages storage and cleanup
- Files automatically deleted after conversation ends

### Upload Flow

**Client Side:**
**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:250`

1. User selects image
2. Resize to 800px width, JPEG 75% quality
3. Save to SwiftData immediately (user message with imageData)
4. Upload to backend in parallel (non-blocking)
5. Backend uploads to OpenAI Files API
6. FileIDs included in `SocketMessage.MessageRequest`

**Server Side:**
**Location:** `Backend/Bloom-Backend/Sources/App/Controllers/Chat/ChatController.swift:50`

1. Receive image data
2. Upload to OpenAI Files API with purpose `.vision`
3. Return fileID array to client
4. Client sends fileIDs in MessageRequest

### Download Pattern

**No Download Flow:**
- Images only uploaded, never downloaded from server
- AI sees images via OpenAI file system
- Client always displays from local SwiftData storage
- Cross-device sync handled by CloudKit (not file download)

---

## Backend Integration

### Server Architecture

**Framework:** Vapor 4
**Database:** PostgreSQL (user data, telemetry)
**Cache:** Redis (chat state, with in-memory fallback)
**Real-time:** WebSocket (with APNs fallback)
**AI:** OpenAI API (o4-mini model)

### Chat Service (ChatService)
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift`

Actor-isolated service managing chat orchestration:

```swift
actor ChatService {
    func on(
        _ message: SocketMessage.MessageRequest,
        userID: UserIdentifier,
        socket: WebSocket
    ) async throws

    func streamResponse(
        userID: UserIdentifier,
        input: [OpenAI.Response.Input],
        conversationID: String?,
        previousResponseID: String?
    ) async throws
}
```

**Responsibilities:**
1. Parse incoming SocketMessage types
2. Build OpenAI input messages
3. Stream OpenAI responses
4. Handle tool calls
5. Manage typing indicators
6. Generate conversation titles
7. Error handling and retries

### OpenAI Integration

#### Model Configuration
**Default Model:** `o4-mini`
**Override Support:** Via feature flags

**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:150`

```swift
let model = user.featureFlags.contains(.gpt4o) ? .o4 : .o4Mini
```

#### Responses API (Not Chat Completions)
**Location:** `Backend/Bloom-Backend/Sources/App/Services/OpenAI/OpenAIService.swift:200`

Uses OpenAI Responses API for conversation continuity:
```swift
struct ResponseRequest {
    let model: Model
    let instructions: String
    let input: [Input]
    let previousResponseID: String?  // Key for conversation context
    let tools: [Tool]
    let reasoning: Reasoning
}
```

**Context Management:**
- V1 clients: `previousResponseID` stored in Redis
- V2 clients: `previousResponseID` provided via `lastMessageID`
- OpenAI maintains conversation context server-side
- No need to send full message history

#### Reasoning Configuration
```swift
reasoning: Reasoning(
    effort: .low,           // Minimize latency
    summary: .auto          // Generate summaries (not shown to user)
)
```

#### Tool Calling
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/Tools/`

Single function tool: `queryUserHealthData`

**Function Definition:**
```swift
Tool(
    type: .function,
    function: Function(
        name: "queryUserHealthData",
        description: "Query the user's health data from HealthKit",
        parameters: HealthQueryParameters(
            dataType: .enum([.nutrition, .workout, .sleep, .vitals]),
            startDate: .string,
            endDate: .string
        )
    )
)
```

**Tool Call Limiting:**
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ToolCallTracker.swift`

- Max 5 tool requests per conversation
- Tracked in `ToolCallTracker` actor
- Tools disabled after limit reached (prevents infinite loops)

**Tool Call Flow:**
1. OpenAI requests tool call
2. Server sends `SocketMessage.ToolCallsRequest` to client
3. Client queries HealthKit
4. Client sends `SocketMessage.ToolCallsResponse` with results
5. Server includes results in next OpenAI request
6. OpenAI generates response using health data

#### Input Building
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:250`

```swift
func buildInputs(
    text: String,
    imageFileIDs: [String]?,
    userInfo: String?,
    extraSystemContext: String?
) -> [OpenAI.Response.Input] {
    var inputs: [OpenAI.Response.Input] = []

    // System message with user context
    inputs.append(.system("""
        You are a helpful health assistant.
        User demographics: \(userInfo ?? "")
        \(extraSystemContext ?? "")
        """))

    // User message with text and images
    var userContent: [Content] = [.text(text)]
    if let fileIDs = imageFileIDs {
        userContent += fileIDs.map { .imageFile(fileID: $0) }
    }
    inputs.append(.user(userContent))

    return inputs
}
```

### WebSocket Server Implementation

#### Registration
**Location:** `Backend/Bloom-Backend/Sources/App/Services/WebSocket/WebSocketService.swift:50`

```swift
actor WebSocketService {
    private var sockets: [UserIdentifier: WebSocket] = [:]

    func register(
        socket: WebSocket,
        for userID: UserIdentifier,
        isV2: Bool
    ) {
        sockets[userID] = socket
        // Store V2 flag for protocol version handling
    }
}
```

**Version Detection:**
- V2 flag based on client app version
- V2 clients send `conversationID` and `lastMessageID`
- V1 clients use Redis for state management

#### Event Handlers
**Location:** `Backend/Bloom-Backend/Sources/App/Routes/WebSocketRoutes.swift:100`

```swift
ws.on(.text) { ws, text in
    let data = Data(text.utf8)
    try await chatService.on(data, userID: userID, socket: ws)
}

ws.on(.binary) { ws, data in
    try await chatService.on(data, userID: userID, socket: ws)
}

ws.on(.ping) { ws, _ in
    try await ws.sendPong()
}

ws.on(.close) { _, _ in
    await webSocketService.unregister(userID: userID)
}
```

#### Message Sending
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatService.swift:900`

```swift
func send<T: Encodable>(
    _ message: T,
    to userID: UserIdentifier
) async {
    // 1. Try WebSocket
    if let socket = await webSocketService.socket(for: userID) {
        let data = try JSONEncoder.bloomModel.encode(message)
        try await socket.send(data)
        return
    }

    // 2. Fallback to APNs
    if let deviceToken = await userService.deviceToken(for: userID) {
        try await apnsService.send(message, to: deviceToken)
        return
    }

    // 3. Cache in Redis (1-hour expiration)
    let data = try JSONEncoder.bloomModel.encode(message)
    try await redisService.lpush("chat_streaming_content:\(userID)", data)
    try await redisService.expire("chat_streaming_content:\(userID)", seconds: 3600)
}
```

**Content Type Handling:**

**Alert Notifications** (Text messages):
```swift
func ensureContentSent(
    _ message: SocketMessage.MessageResponse,
    to userID: UserIdentifier
) async {
    // Send with alert notification
    await apnsService.send(
        alert: "New message from Bud",
        data: message,
        to: deviceToken
    )
}
```

**Background Notifications** (Tool calls, rich content):
```swift
func ensureContentSilentlySent(
    _ message: SocketMessage.ToolCallsRequest,
    to userID: UserIdentifier
) async {
    // Send silent background notification
    await apnsService.sendBackground(
        data: message,
        to: deviceToken
    )
}
```

### Database Schema

#### PostgreSQL Schema

**ChatMessageIssueReport Table:**
**Location:** `Backend/Bloom-Backend/Sources/App/Migrations/CreateChatMessageIssueReport.swift`

```swift
schema.create("chat_message_issue_reports") { table in
    table.id()
    table.field("response_id", .string, .required)
    table.field("notes", .string)
    table.field("app_version", .string)
    table.field("user_id", .uuid, .references("users", "id"))
    table.field("created_at", .datetime)
}
```

**No Chat Messages in PostgreSQL:**
- Chat messages stored client-side only (SwiftData + CloudKit)
- Server is stateless for messages
- Only metadata and issue reports in PostgreSQL

#### Redis Schema

**Keys:**

1. **Last Response ID** (V1 clients only)
   - Key: `chat_last_response_id:{userID}`
   - Type: String
   - Value: OpenAI response ID
   - Expiration: None

2. **Tool Call Tracking**
   - Key: `chat_function_call_ids:{userID}`
   - Type: Set<String>
   - Value: Tool call IDs
   - Expiration: None
   - Usage: Track pending tool calls for fortification

3. **Streaming Content Queue**
   - Key: `chat_streaming_content:{userID}`
   - Type: List<Data>
   - Value: Encoded SocketMessage types
   - Expiration: 1 hour
   - Usage: Queue messages when WebSocket disconnected

#### Redis Health Management
**Location:** `Backend/Bloom-Backend/Sources/App/Services/Redis/RedisService.swift:500`

```swift
actor RedisService {
    private var isHealthy = true
    private var fallbackStorage: [String: Any] = [:]

    func get<T>(_ key: String) async throws -> T? {
        if isHealthy {
            do {
                return try await redis.get(key)
            } catch {
                // Mark unhealthy, retry after 30 seconds
                isHealthy = false
                Task {
                    try await Task.sleep(for: .seconds(30))
                    await checkHealth()
                }
                // Fallback to in-memory storage
                return fallbackStorage[key] as? T
            }
        } else {
            return fallbackStorage[key] as? T
        }
    }

    func set<T>(_ key: String, value: T) async throws {
        if isHealthy {
            try await redis.set(key, to: value)
        } else {
            // Store in-memory until Redis recovers
            fallbackStorage[key] = value
        }
    }

    private func checkHealth() async {
        do {
            try await redis.ping()
            isHealthy = true
            // Sync fallback data to Redis
            for (key, value) in fallbackStorage {
                try await redis.set(key, to: value)
            }
            fallbackStorage.removeAll()
        } catch {
            // Still unhealthy, retry later
        }
    }
}
```

**Fallback Behavior:**
- Automatic fallback to in-memory storage on Redis failure
- Retry connection after 30 seconds
- Sync fallback data when Redis recovers
- No user-facing errors

---

## Breaking Changes

### What Constitutes a Breaking Change

#### Model Changes

**1. SwiftData Schema Changes**

**Breaking:**
- Adding/removing properties
- Changing property types
- Relationship changes
- Changing `@Attribute` configuration

**Impact:**
- All users must migrate on app update
- Migration failures can cause data loss

**Migration Path:**
```swift
// Create V29 schema
@Model
final class ChatMessageV29 {
    // New property
    var newProperty: String?
}

// Update VersionedSchema
enum ChatSchemaV29: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(29, 0, 0)
    static var models: [any PersistentModel.Type] = [
        ChatMessageV29.self,
        ChatConversationV29.self
    ]
}

// Add migration plan
static var migrationPlan: [MigrationStage] = [
    MigrationStage.custom(
        fromVersion: ChatSchemaV28.self,
        toVersion: ChatSchemaV29.self,
        willMigrate: { context in
            // Custom migration logic
        }
    )
]
```

**Mitigation:**
- SwiftData handles migration automatically
- Test thoroughly with large datasets
- Consider backward compatibility for CloudKit sync

**2. SocketMessage Protocol Changes**

**Breaking:**
- Removing fields from existing message types
- Changing field types
- Renaming fields
- Changing message type enum cases

**Safe:**
- Adding optional fields (backward compatible)
- Adding new message types
- Adding new enum cases (if handled with default/unknown)

**Example Breaking Change:**
```swift
// V1 (Old)
struct MessageRequest {
    let text: String
    let requestID: String
}

// V2 (New) - BREAKING
struct MessageRequest {
    let text: String
    let requestID: String
    let conversationID: String  // New REQUIRED field
}
```

**Impact:**
- Old clients can't decode new messages
- New clients can't decode old messages
- Mixed client/server versions fail
- All active conversations fail

**Mitigation:**
```swift
// Safe approach: Make new field optional
struct MessageRequest {
    let text: String
    let requestID: String
    let conversationID: String?  // Optional - backward compatible
}

// Server handles both versions
if let conversationID = message.conversationID {
    // V2 client
} else {
    // V1 client (fallback to Redis-based state)
}
```

**3. DTO Changes**

**Breaking:**
- Removing properties
- Type changes
- Making optional properties required

**Safe:**
- Adding optional properties
- Making required properties optional (with default handling)

**Impact:**
- Compile-time errors throughout codebase
- Actor communication failures

**Mitigation:**
- Version DTOs if needed
- Provide migration utilities

#### API Changes

**1. WebSocket Protocol Changes**

**Breaking:**
- New required fields in any SocketMessage type
- Removing response fields
- Changing message encoding format
- Changing WebSocket URL or authentication

**Impact:**
- All active conversations fail immediately
- Users must restart app or reconnect

**Example:**
```swift
// Breaking: Changing WebSocket authentication
// Old: Token in URL query parameter
ws://api.bloom.com/chat?token=abc123

// New: Token in header
ws://api.bloom.com/chat
Headers: { "Authorization": "Bearer abc123" }
```

**Mitigation:**
- Use version flag in WebSocket handshake
- Support both protocols temporarily
- Deprecation period with client version enforcement

**2. REST Endpoints Changes**

**Breaking:**
- Adding required parameters
- Changing response format
- Removing endpoints
- Changing request/response types

**Safe:**
- Adding optional parameters
- Adding new endpoints
- Adding optional response fields

**Example Breaking Change:**
```swift
// Old endpoint
POST /v1/chat/upload-image
Request: { "imageData": Data }
Response: [String]  // Array of fileIDs

// Breaking: Changing response format
Response: { "fileIDs": [String], "uploadedAt": Date }
```

**Impact:**
- Old clients can't parse new responses
- Requests fail with decoding errors

**Mitigation:**
```swift
// Use API versioning
POST /v1/chat/upload-image  // Old version
POST /v2/chat/upload-image  // New version

// Or make new fields optional
Response: {
    "fileIDs": [String],
    "uploadedAt": Date?  // Optional - old clients ignore
}
```

**3. File Upload Format Changes**

**Breaking:**
- Image format requirements
- File size limits (reducing)
- Response format changes

**Safe:**
- Increasing file size limits
- Supporting additional image formats

**Impact:**
- Image send failures
- User-facing errors

#### State Management Changes

**1. Redis Key Format Changes**

**Breaking:**
- Changing key naming convention
- Changing value encoding
- Changing data structure (String → Hash, etc.)

**Example:**
```swift
// Old
chat_last_response_id:{userID}  // String value

// Breaking
chat:response:{userID}:last  // Different key format
```

**Impact:**
- Lost conversation context
- Tool call failures
- Orphaned data in Redis

**Mitigation:**
- Clear Redis on deploy (acceptable for ephemeral state)
- Migration script for critical data
- Graceful handling of missing keys

**2. Conversation ID Handling Changes**

**Current V1 → V2 Migration:**
- V1: No `conversationID` in messages (Redis-based, single conversation)
- V2: Client provides `conversationID` (multi-conversation support)

**Removing V1 Support Would Be Breaking:**

**Impact:**
- Old clients can't chat
- All V1 users must update app

**Mitigation:**
- Long deprecation period (6+ months)
- Server-side detection of client version
- Forced app update for critical changes

#### Rich Content Changes

**1. ProcessedRichContent Types**

**Breaking:**
- Changing structure of existing types
- Removing support for types
- Changing enum case names

**Safe:**
- Adding new types (falls back to `.unknown`)
- Adding optional fields to existing types

**Example:**
```swift
// Old
case logWeight(weight: Double, unit: String)

// Breaking
case logWeight(WeightLog)  // Different structure

// Safe
case logWeight(weight: Double, unit: String, timestamp: Date?)  // Added optional
```

**Impact:**
- Rich content renders as "unknown"
- Auto-logging fails
- User confusion

**Mitigation:**
```swift
// Versioned rich content parsing
switch richContent.version {
case 1:
    return parseV1(richContent)
case 2:
    return parseV2(richContent)
default:
    return .unknown
}
```

**2. Auto-Log Actions**

**Breaking:**
- Changing HealthKit data format
- Changing required fields
- Removing action types

**Safe:**
- Adding new action types
- Making fields optional (with sensible defaults)

**Example:**
```swift
// Breaking: Changing HealthKit write format
// Old
logWeight(value: 150.0, unit: "lb")

// Breaking
logWeight(value: 150.0, unit: .pounds, timestamp: Date(), source: "Bud")
// New required fields: timestamp, source
```

**Impact:**
- Auto-logging fails
- User must manually log data
- Error messages in chat

**Mitigation:**
- Provide defaults for new fields
- Graceful fallback to manual logging

#### CloudKit Sync Changes

**1. Model Property Changes**

**Breaking:**
- Adding required (non-optional) properties
- Changing property types
- Removing properties

**Impact:**
- Sync failures across devices
- Data loss
- App crashes on older devices

**Example:**
```swift
// Breaking for CloudKit
@Model
final class ChatMessage {
    var id: String
    var message: String  // Changed from String? to String
}
```

**CloudKit Requirement:**
- All properties must be optional or have default values
- CloudKit records must be backward compatible

**Mitigation:**
- Keep all properties optional
- Add new properties as optional
- Never remove properties (deprecated but kept)

### Version Management Strategy

#### Current Approach

**1. SwiftData Versioning**
- Schema versioning: V0 → V28
- Migration plans between versions
- Automatic migration on app update

**2. API Versioning**
- v1 prefix on all REST endpoints
- Explicit versioning in URL path

**3. WebSocket Protocol Versioning**
- Version flag: `message.isV2`
- Server detects client version
- Conditional handling of V1 vs V2

**4. Feature Flags**
- Model override (o4 vs o4-mini)
- Feature rollout control

#### Recommended Practices

**1. Explicit Protocol Versioning**
```swift
// WebSocket handshake
struct HandshakeMessage {
    let protocolVersion: Int  // 1, 2, 3, etc.
    let clientVersion: String  // "1.0.0"
}
```

**2. Graceful Degradation**
```swift
// Handle unknown message types
do {
    let message = try decoder.decode(SocketMessage.self, from: data)
    handle(message)
} catch {
    // Log unknown message type, don't crash
    TelemetryDeck.signal("unknown_socket_message")
}
```

**3. Long Support Windows**
- Maintain V1 support for 6+ months after V2 release
- Force update for critical security/stability fixes
- Clear deprecation timeline communicated to users

**4. Backward-Compatible Changes**
```swift
// Always make new fields optional
struct MessageRequest {
    let text: String
    let requestID: String
    let conversationID: String?     // V2 - optional
    let extraContext: String?       // V3 - optional
}
```

**5. Feature Toggles**
```swift
// Server-side feature flags
if user.appVersion >= "2.0.0" {
    // Use V2 protocol
} else {
    // Use V1 protocol
}
```

---

## Key Implementation Details

### V1 vs V2 Protocol Differences

#### V1 (Legacy - Single Conversation)
**Client Behavior:**
- No `conversationID` in messages
- No `lastMessageID` tracking
- Single conversation per user

**Server Behavior:**
- Store `previousResponseID` in Redis
- Key: `chat_last_response_id:{userID}`
- Global state per user (not per conversation)

#### V2 (Current - Multi Conversation)
**Client Behavior:**
- Send `conversationID` in all messages
- Send `lastMessageID` for context continuity
- Multiple conversations per user

**Server Behavior:**
- Use client-provided `lastMessageID`
- No Redis storage for response IDs (client manages)
- Per-conversation state

**Detection:**
```swift
let isV2 = message.conversationID != nil
```

### Context Window Management

**OpenAI Context:**
- Managed via `previousResponseID` parameter
- OpenAI maintains conversation context server-side
- No need to send full message history

**V1 Context:**
```swift
// Server fetches from Redis
let previousResponseID = try await redis.get("chat_last_response_id:\(userID)")
```

**V2 Context:**
```swift
// Client provides via lastMessageID
let previousResponseID = conversation.lastMessageID
```

**Client Tracking:**
```swift
// Update on ResponseCompleted
func handleResponseCompleted(_ message: SocketMessage.ResponseCompleted) {
    conversation.lastMessageID = message.lastMessageID
    try await conversationActor.updateLastMessageID(
        message.lastMessageID,
        for: conversationID
    )
}
```

### Tool Call Limiting

**Location:** `Backend/Bloom-Backend/Sources/App/Services/Chat/ToolCallTracker.swift`

```swift
actor ToolCallTracker {
    private var toolCallCounts: [String: Int] = [:]
    private let maxToolCalls = 5

    func shouldAllowToolCall(for conversationID: String) -> Bool {
        let count = toolCallCounts[conversationID] ?? 0
        return count < maxToolCalls
    }

    func incrementToolCallCount(for conversationID: String) {
        toolCallCounts[conversationID, default: 0] += 1
    }
}
```

**Rationale:**
- Prevents infinite tool call loops
- Limits OpenAI API costs
- 5 calls sufficient for most health queries

**Behavior After Limit:**
- Tools disabled in OpenAI request
- AI continues with available data
- No error shown to user

### Throttling for Smooth Streaming

**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:420`

```swift
private var throttleTask: Task<Void, Never>?

func appendChunk(_ chunk: String, to conversationID: String) {
    // Buffer chunk immediately
    inProgressMessages[conversationID].append(chunk)

    // Throttle UI updates to 100ms
    throttleTask?.cancel()
    throttleTask = Task {
        try? await Task.sleep(for: .milliseconds(100))
        await publishInProgressMessages()
    }
}
```

**Rationale:**
- Prevent UI jank from rapid updates
- Smooth streaming experience
- Balance between responsiveness and performance

### Auto-Logging of Rich Content

**Location:** `Apps/Bloom/Bloom/UserInterface/Chat/ChatLogic/ChatController.swift:550`

```swift
func handleRichMessage(_ message: SocketMessage.RichMessageResponse) async {
    if message.isPermanent {
        // Auto-execute action
        let dbID = try await executeAction(message.content)

        // Save to SwiftData with dbID
        let chatMessage = ChatMessage(
            richContent: message.content,
            dbID: dbID,
            hasPerformedAction: true
        )
        try await messageActor.save(chatMessage)
    } else {
        // Show in UI, don't save (temporary)
        inProgressMessages[conversationID].append(message)
    }
}
```

**Permanent Actions:**
- Weight logging
- Period tracking
- Water intake
- Blood pressure
- Bowel movements
- Workout creation
- Reminder creation

**Temporary Actions:**
- Detected food (user must confirm)
- Goals (user must review)

**Key Points:**
- `hasPerformedAction` prevents duplicate execution
- `dbID` links message to HealthKit sample
- User can view logged data from chat message

### Redis Health Management

**Features:**
- Automatic fallback to in-memory storage
- Health check every 30 seconds
- Sync fallback data when Redis recovers
- No user-facing errors

**Graceful Degradation:**
- V1 clients: Lost context on Redis failure (minor UX impact)
- V2 clients: No impact (client-managed context)
- Streaming content queue: Lost on Redis failure (fallback to APNs)

---

## Summary

The Bloom chat system is a production-ready, sophisticated architecture with:

- **Dual-version support** (V1 legacy, V2 multi-conversation)
- **Resilient state management** (Redis with in-memory fallback)
- **Streaming-first design** with rich content support
- **Deep health integration** via OpenAI tool calling
- **Actor-based concurrency** for thread safety
- **CloudKit sync** for cross-device persistence
- **Comprehensive error handling** with telemetry
- **Fallback to APNs** when WebSocket unavailable
- **Auto-logging** of health actions from AI responses
- **Throttled updates** for smooth streaming UX
- **OpenAI Responses API** with reasoning and tool calling

### Breaking Change Checklist

When making changes, ask:

- [ ] Does this change SwiftData schema? → Requires migration
- [ ] Does this change SocketMessage protocol? → Requires versioning
- [ ] Does this change REST endpoints? → Use API versioning
- [ ] Does this change Redis keys? → Clear on deploy or migrate
- [ ] Does this change rich content format? → Version or default to unknown
- [ ] Does this change WebSocket protocol? → Support both versions
- [ ] Is this backward compatible with V1 clients? → Consider deprecation timeline
- [ ] Does this affect CloudKit sync? → Ensure properties remain optional
- [ ] Have you tested with mixed client versions? → Verify graceful degradation

### Development Best Practices

**1. Adding New SocketMessage Types** (Safe)
```swift
// Add new case to enum
extension SocketMessage {
    case newFeature(NewFeatureMessage)
}

// Old clients ignore unknown types (graceful degradation)
```

**2. Adding Properties to Existing Messages** (Use Optional)
```swift
struct MessageRequest {
    let text: String
    let newField: String?  // Optional - backward compatible
}
```

**3. Adding New Rich Content Types** (Safe)
```swift
enum RichMessageKind {
    case existingType
    case newType  // Falls back to .unknown on old clients
}
```

**4. Modifying SwiftData Schema**
```swift
// Create V29, add migration plan
// Test thoroughly with large datasets
```

**5. Changing API Endpoints**
```swift
// Use versioning
POST /v1/chat/upload-image  // Old
POST /v2/chat/upload-image  // New
```

**6. Testing Protocol Changes**
- Test with V1 and V2 clients simultaneously
- Verify graceful degradation
- Test WebSocket reconnection scenarios
- Test APNs fallback behavior
- Monitor telemetry for errors

---

For questions or clarifications about this architecture, refer to:
- `CLAUDE.md` - Development guidelines
- `ARCHITECTURE.md` - General architectural patterns
- Code comments in referenced files
