# Bloom Architecture Patterns & Conventions

This document outlines the common patterns, conventions, and best practices used throughout the Bloom codebase.

## Architecture Patterns

### MVVM with @Observable
```swift
@Observable @MainActor
final class ChatViewModel {
    var assistantTypingStatus: String?
    var assistantIsTyping = false
    var inProgressMessages = [ChatController.InProgressMessage]()
    var error: Error?
    
    init() {
        setupObservers()
    }
}
```

### Actor-Based Architecture
```swift
final actor ChatVitalConverter {
    static let shared = ChatVitalConverter()
    private init() { }
}

// Model actors for thread-safe data access
actor FoodItemLogModelActor {
    static func standard() -> FoodItemLogModelActor { }
}
```

### Dependency Injection via Environment
```swift
@Environment(TabController.self) private var tabController: TabController
@Environment(\.modelContext) private var modelContext
```

## SwiftUI Patterns

### View Composition
```swift
struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @Query private var chatMessages: [ChatMessage]
    
    init() {
        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        _chatMessages = Query(descriptor, animation: .default)
    }
}
```

### Custom View Modifiers
```swift
// Consistent background styling
.groupedBackground()
.cardContainer()
.roundedBackground(Color.container, cornerRadius: 16)
```

### SwiftUI Styling Conventions
```swift
// ALWAYS use .foregroundStyle instead of .foregroundColor
Text("Example")
  .foregroundStyle(.primary)  // ✅ Correct
  .foregroundStyle(.secondary) // ✅ Correct
  .foregroundStyle(.accent)    // ✅ Correct (not .accentColor)

// DON'T use deprecated .foregroundColor
Text("Example")
  .foregroundColor(.primary)   // ❌ Deprecated
```

### Private Extension Pattern
```swift
private extension ChatView {
    func updateCells() { }
    var bottomAnchorView: some View { }
}
```

### Sheet Presentation Pattern
Use the `presentedSheet: AnyView?` pattern for presenting modal sheets throughout the app:

```swift
struct MyView: View {
  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack {
      Button("Show Detail") {
        presentedSheet = DetailView().asAny
      }
    }
    .sheet($presentedSheet)
  }
}
```

**Benefits:**
- Type-erased sheet presentation without complex state management
- Single binding handles all sheet presentations
- Consistent pattern across the codebase
- Works seamlessly with the `.sheet($presentedSheet)` modifier

## Data Flow Patterns

### SwiftData with DTOs
```swift
// Persistent model
@Model
final class ChatMessage {
    var id: String
    var isCurrentUser: Bool
    var content: ChatContent
    var date: Date
}

// Network/transfer objects
struct ChatHealthData: SendableNetworkModel {
    let demographics: UserInfo?
    let activityLevel: ActivityLevel?
}

// DTOs for thread-safe data passing (located in DataContainer/SwiftData/Schema/DTOs/)
// Each DTO is in its own file and includes all model properties
struct ReminderDTO: Sendable, Equatable, Identifiable {
    public let persistentModelID: PersistentIdentifier
    public let id: String
    public let title: String
    // ... all other properties from the model
}

// Models have asDTO() method defined in the DTO file
extension SchemaV18.Reminder {
    public func asDTO() -> ReminderDTO {
        ReminderDTO(
            persistentModelID: persistentModelID,
            id: id,
            title: title
            // ... map all properties
        )
    }
}
```

### HealthKit Integration
```swift
extension TargetMetric {
    func fetchCollatedDailyQuantity(
        unit: HKUnit,
        dateRange: DateRange
    ) async -> [DateQuantitySample] { }
}
```

### Async Stream Pattern
```swift
for await assistantTypingStatus in await ChatController.shared.$assistantTypingStatus {
    await MainActor.run { [weak self] in
        self?.assistantTypingStatus = assistantTypingStatus
    }
}
```

## Networking Patterns

### Request/Response Pattern
```swift
extension URLRequest {
    static func submitChatMessage(body: ChatMessageRequest) -> URLRequest {
        URLRequest(
            host: .api,
            method: .post,
            endpoint: "/v1/chat",
            headers: .authorization
        )
        .encoding(body)
    }
}
```

### WebSocket Management
```swift
final class WebSocketHandle: NSObject {
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    
    func send<T: Encodable>(payload: T) async throws { }
}
```

### Error Handling
```swift
do {
    try await performOperation()
} catch {
    TelemetryDeck.errorOccurred(
        id: "OperationName",
        category: .thrownException,
        message: error.localizedDescription
    )
    self.error = error
}
```

## Common Utilities & Extensions

### Date Formatting
All date formatters are centralized in `BloomFoundation/Formatters/DateFormatter+Constants.swift` for consistency:

```swift
// Common formatters available throughout the app
static let dateTimeMediumWithTimeZone = DateFormatter().with {
    $0.dateFormat = "MMM d, yyyy h:mm a zzz"  // "Nov 28, 2025 3:45 PM PST"
}

static let justDateShort = DateFormatter().with {
    $0.dateStyle = .short
    $0.timeStyle = .none
}

static let relativeDateTimeMedium = DateFormatter().with {
    $0.dateStyle = .medium
    $0.timeStyle = .medium
    $0.doesRelativeDateFormatting = true  // Shows "Today", "Yesterday", etc.
}

// Duration formatters
static let timeIntervalHourMinuteSecondShort = DateComponentsFormatter().with {
    $0.unitsStyle = .short
    $0.allowedUnits = [.hour, .minute, .second]
}
```

### With Pattern
```swift
extension NSObject {
    func with(_ configure: (Self) -> Void) -> Self {
        configure(self)
        return self
    }
}
```

### Public Extension Pattern
When creating extensions for types that need to be accessed across modules, use `public extension` rather than making individual members public:

```swift
// Preferred: Make the entire extension public
public extension ReminderDTO {
    var nextNotificationDate: Date? { /* implementation */ }
    var color: Color { /* implementation */ }
    func someMethod() { /* implementation */ }
}

// Avoid: Making individual members public
extension ReminderDTO {
    public var nextNotificationDate: Date? { /* implementation */ }
    public var color: Color { /* implementation */ }
    public func someMethod() { /* implementation */ }
}
```

This pattern is cleaner, more maintainable, and makes the public interface intent clear at the extension level.

### Date and Calendar Helpers
Before implementing custom date manipulation:
1. **Check Calendar+Helpers.swift** in `BloomFoundation/Calendar/` for existing calendar utilities:
   - `startOfWeek(for:)`, `startOfMonth(for:)`, `startOfYear(for:)`
   - `endOfDay(for:)`, `startOfTomorrow(for:)`
   - `mondayMorning(for:)`, `timeOfDay(for:)`
   - `iterate(dateRange:by:iterator:)` for date iteration
   - Many other helpful date/time utilities

2. **Check DateRange.swift** in `BloomFoundation/Date/` for static date range helpers:
   - `DateRange.today()`, `DateRange.yesterday()`, `DateRange.tomorrow()`
   - `DateRange.startOfWeekToNow()`, `DateRange.startOfMonthToNow()`
   - `DateRange.trailingDaysFromNow(_:)`, `DateRange.trailingWeeksFromNow(_:)`
   - Many other pre-built date ranges

Using these existing utilities ensures consistency and prevents duplicate implementations.

### Collection Extensions
```swift
extension Collection {
    var isNotEmpty: Bool { !isEmpty }
    
    func average<T: BinaryFloatingPoint>(keyPath: KeyPath<Element, T>) -> T { }
}
```

### Throttling
```swift
final class Throttler {
    private var task: Task<Void, Never>?
    
    func throttle(seconds: TimeInterval, operation: @escaping () async -> Void) { }
}
```

## Testing Patterns

### Swift Testing Framework
```swift
import Testing

@Suite("Calorie Target Calculator")
struct CalorieTargetCalculatorTestSuite {
    @Test("BMR Calculation", arguments: CalorieTargetCalculatorSuiteArguments.bmr)
    func testBMR(args: CalorieTargetCalculatorSuiteArguments.BMRArguments) throws {
        let bmr = CalorieTargetCalculator.bmr(args.profile)
        #expect(bmr == args.expected)
    }
}
```

## Code Organization

### Module Structure
- `BloomFoundation` - Shared utilities and extensions
- `CoreHealth` - HealthKit abstractions
- `DataContainer` - SwiftData models and actors
- `BloomModel` - Shared network models
- `ScreenControl` - Family Controls APIs

### Widgets & App Intents Organization
```
Apps/Bloom/
├── BloomWidgets/           # Widget extension target
│   ├── BloomWidgetsBundle.swift
│   ├── BloomWidgets.swift
│   └── BloomWidgetsControl.swift
└── SharedAppIntents/       # Shared App Intents (multi-target)
    └── [App Intent files]
```

**Key Patterns:**
- **Widgets**: All widget implementations live in `Apps/Bloom/BloomWidgets/`
- **App Intents**: Shared App Intents go in `Apps/Bloom/SharedAppIntents/`
- **Target Membership**: Files in `SharedAppIntents/` have dual target membership:
  - Main app target (`Bloom`)
  - Widget extension target (`BloomWidgets`)
- **Purpose**: This allows App Intents to be used by both the main app and widgets without code duplication
- **Widget Types**: Support for both standard widgets and Control Center widgets (ControlWidget)

**Implementation Notes:**
- Use `AppIntentTimelineProvider` for widget timeline management
- Configure App Intents to be accessible from both targets in Xcode's target membership settings
- Follow WidgetKit best practices for timeline updates and relevance

### File Organization
```
UserInterface/
├── Chat/
│   ├── ChatView.swift
│   ├── ChatViewModel.swift
│   ├── Components/
│   └── Converters/
```

Keep views modular - extract reusable components into separate files in the Components/ folder rather than defining them inline. This improves reusability and keeps files focused.

## Naming Conventions

### ViewModels
- Suffix: `ViewModel`
- Example: `ChatViewModel`, `VitalsViewModel`

### Model Actors
- Suffix: `ModelActor`
- Example: `FoodItemLogModelActor`, `HabitModelActor`

### Network Models
- Protocol: `SendableNetworkModel`
- Nested types for organization

### View Extensions
- Pattern: `View+{Feature}.swift`
- Example: `View+FlippedVertically.swift`

### UI Component Naming
- **Cell**: Components used within a view (e.g., `ReminderEditCell`, `FoodItemCell`)
- **Card**: Modal views that don't cover the entire screen (e.g., `HealthGoalEditCard`, `NewGoalCard`)
- **View**: Full screens or complex components (e.g., `SettingsView`, `CreateEditReminderView`)

## Concurrency Patterns

### Task Management
```swift
private var typingStatusTask: Task<Void, Never>?

deinit {
    typingStatusTask?.cancel()
}
```

### MainActor Usage
```swift
@MainActor
func updateUI() async { }

await MainActor.run {
    self.property = newValue
}
```

## SwiftData Patterns

### Model Configuration
```swift
@Model
final class FoodItemLogDTO {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .cascade) var foodItemServings: [FoodItemServing]
}
```

### Migration Strategy
```swift
enum DataContainerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        DataContainerSchemaV1.self,
        DataContainerSchemaV2.self
    ]
    
    static var stages: [MigrationStage] = []
}
```

### Schema Evolution Pattern

**CRITICAL RULE**: Never modify shipped schema files! Once shipped, create new versions for changes.

#### When to Create New Schema Version:
- **Before shipping**: You can modify existing schemas freely
- **After shipping**: Must create new schema version for any changes

#### Schema Modification Process:
1. **Ask if shipped**: Confirm whether the current schema has been shipped to users
2. **If not shipped**: Modify existing schema files directly
3. **If shipped**: Follow versioning process:
   - Create new schema version (e.g., V19 → V20)
   - Copy affected model files to new version directory with version suffix
   - Modify models in new version only
   - Update typealias to point to new version
   - Create migration stage
   - Update migration plan

#### File Naming Convention:
SwiftData model files must include the version number in the filename:
```
V20/
├── ReminderV20.swift           # Correct: includes version
├── ReminderOccurrenceV20.swift
└── ReminderCompletionRecordV20.swift
```
This prevents naming conflicts and makes version tracking explicit.

#### Schema Version Declaration:
```swift
enum SchemaV20: VersionedSchema {
    static let models: [any PersistentModel.Type] = [
        SchemaV17.BowelMovement.self,  // Reference existing models from their version
        SchemaV15.ChatMessage.self,
        SchemaV20.Reminder.self,        // Updated models use new version
        SchemaV20.ReminderOccurrence.self,
        SchemaV20.ReminderCompletionRecord.self
    ]
}
```

#### Typealias Pattern:
Use typealias to avoid schema-specific code throughout the app:
```swift
// In ModelTypealiases.swift
public typealias ReminderCompletionRecord = SchemaV20.ReminderCompletionRecord

// In DTOs - use typealias, not specific schema version
extension ReminderCompletionRecord {
    public func asDTO() -> ReminderCompletionRecordDTO { }
}
```

#### Migration Types:
- **Lightweight**: For adding optional properties, simple changes
- **Custom**: For complex data transformations, relationship changes

This approach maintains clear version tracking while minimizing code duplication through typealias usage.

### Database Migration Organization Pattern
All migrations for a given model should be organized in the model's main migrations file, not in separate files:

```swift
// ✅ CORRECT: All migrations in one file
// FoodItemRecord+Migrations.swift
extension FoodItemRecord {
  struct Create: AsyncMigration { ... }
  struct AddNutrients: AsyncMigration { ... }
  struct FixNutritionFieldTypes: AsyncMigration { ... }
  struct AddDuplicateFields: AsyncMigration { ... }
}

// ❌ AVOID: Separate migration files
// FoodItemRecord+DuplicateFieldsMigration.swift
// FoodItemRecord+NutrientsMigration.swift
```

**Benefits of consolidated migrations:**
- **Single source of truth**: All schema changes for a model in one place
- **Better git history**: Related migrations are versioned together
- **Easier maintenance**: No need to search across multiple files for migration history
- **Consistent pattern**: Follows the same organization as other backend models

**When adding new migrations:**
1. Add the new migration struct to the existing `{Model}+Migrations.swift` file
2. Follow the existing naming pattern (`AddFeatureName`, `FixFieldTypes`, etc.)
3. Include both `prepare` and `revert` methods
4. Register in `AllMigrations.swift`
5. **Use FluentEnum pattern for enums**: Reference the actual enum type, not string literals

### FluentEnum Pattern for Database Migrations
When creating database enums in migrations, always use the FluentEnum pattern with the actual enum type:

**Prerequisites**: The enum must conform to `FluentEnum` protocol:
```swift
enum AdminStatus: String, Codable, CaseIterable, FluentEnum {
  static let schema = "admin_status"
  
  case pending
  case markedDistinct = "marked_distinct"
}
```

**Migration usage**:
```swift
// ✅ CORRECT: Use the enum type directly
let adminStatusEnum = try await database.enum(AdminStatus.self)
  .case(.pending)
  .case(.markedDistinct)
  .create()

// ❌ AVOID: String-based enum creation
let adminStatusEnum = try await database.enum("admin_status")
  .case("pending")
  .case("marked_distinct")
  .create()
```

**Benefits of FluentEnum pattern:**
- **Type safety**: Compile-time checking ensures enum cases match
- **Refactoring safety**: IDE can rename enum cases across codebase
- **Consistency**: Matches the established pattern used in existing migrations
- **Less error-prone**: No risk of typos in string literals

**In revert methods**, also use the enum type:
```swift
try await database.enum(AdminStatus.self).delete()
```

### Model Organization Pattern
SwiftData models are organized to separate core definitions from helper methods:
```
Schema/
├── V18/
│   ├── SchemaV18.swift         # Schema definition
│   └── Reminder.swift          # Core model definition (properties, relationships, init)
├── Extensions/
│   └── Models/
│       └── Reminder+Helpers.swift  # Extension methods, computed properties
└── DTOs/
    └── ReminderDTO.swift       # DTO with all properties and asDTO() extension
```

Keep model definitions lean with only stored properties, relationships, and initializers. Move all helper methods, computed properties, and business logic to extension files.

## Error Handling

### User-Facing Errors
```swift
.alert(error: $viewModel.error)
```

### Telemetry Integration
```swift
TelemetryDeck.signal("Event Name", parameters: ["key": "value"])
TelemetryDeck.errorOccurred(id: "Error ID", category: .thrownException)
```

## Performance Patterns

### Lazy Loading
```swift
LazyVStack {
    ForEach(items) { item in
        ItemView(item: item)
    }
}
```

### View Update Optimization
```swift
// Only update if actually different
if self.models != newModels {
    self.models = newModels
}
```

### Memory Management
```swift
Task.detached { [weak self] in
    // Capture self weakly in long-running tasks
}
```

## Security & Privacy

### No Logging of Personal Data
```swift
// Never log health data values
print("Querying Health Data [\(query.dataType.rawValue)]")
// NOT: print("Heart rate: \(heartRate)")
```

### Secure Storage
```swift
// Use Keychain for sensitive data
// Use UserDefaults.group for app group data
```

## Best Practices

1. **Always use workspace**: `open Bloom.xcworkspace`
2. **Run SwiftLint**: `./Apps/Bloom/Scripts/swiftlint.sh`
3. **Strict Concurrency**: Swift 6 with complete checking enabled
4. **Preview Development**: 
   - Wrap previews in `PreviewEnvironment {}`
   - No need for `#if DEBUG` - previews are automatically excluded from release builds
   - Every view should have a preview for development
5. **ScrollView Usage**: Use `BloomScrollView` for consistent behavior
6. **List Cells**: Use `.cardContainer()` for consistent styling
7. **Create files only when necessary**: Prefer editing existing files
8. **Follow existing patterns**: Check similar features before implementing
9. **Code Indentation**: Use 2 spaces for indentation (not tabs)
10. **SF Symbols**: Always use SFSafeSymbols for type-safe symbol definitions instead of string literals
11. **SwiftData Models**: Never make SwiftData models conform to `Sendable`. Use DTOs for thread-safe data transfer and avoid `@preconcurrency import` or `nonisolated(unsafe)` with SwiftData models

## Custom JSON Encoding

### Date Encoding with Timezone (AI Chat Only)
**Note: This special timezone handling is specifically for sending user health data to the AI in chat contexts. Regular API communication uses standard JSON encoding.**

```swift
// Used in ChatHealthQueryPerformer.swift for AI context
private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        // Formats as "Nov 28, 2025 3:45 PM PST" in user's timezone
        let dateString = DateFormatter.dateTimeMediumWithTimeZone.string(from: date)
        try container.encode(dateString)
    }
    return encoder
}()
```

For all other API communication, use the standard encoder:
```swift
JSONEncoder.bloomModel  // Standard encoding with ISO8601 dates
```

## Type Safety Patterns

### Sendable Conformance
```swift
protocol SendableNetworkModel: Codable, Equatable, Sendable { }
```

### Strong Typing with Enums
```swift
enum ChatCellType: Equatable {
    case message(ChatMessage)
    case inProgress(ChatController.InProgressMessage)
    case typingIndicator
    case statusText(String)
    case prompts
}
```

## AI Chat Integration Patterns

### Adding New AI Capabilities
When adding new capabilities for the AI assistant to create or manage data, follow this pattern:

#### 1. Create SocketMessage Models (BloomModel)
Define models in `Shared/BloomModel/Sources/BloomModel/Chat/SocketMessage/SocketMessage+{Feature}.swift`:

```swift
public extension SocketMessage {
  struct CreateReminder: Codable, Equatable, Sendable {
    public let title: String
    public let color: String
    public let occurrences: [ReminderOccurrence]
    
    public init(title: String, color: String, occurrences: [ReminderOccurrence]) {
      self.title = title
      self.color = color
      self.occurrences = occurrences
    }
  }
  
  // Use string-based enums for better AI comprehension
  enum CadenceType: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
  }
}
```

**Key principles:**
- Use string raw values for enums (better AI understanding)
- Include clear documentation in comments
- Follow existing SocketMessage naming patterns
- Make all types `Codable, Equatable, Sendable`

#### 2. Add Function Schema (Backend)
Define the JSON schema in `Backend/Bloom-Backend/Sources/App/Services/AI/Prompts/String+FunctionSchema.swift`:

```swift
static let createReminder: String = """
  Create Reminder: {
    "title": String,                     // Required. Short title using title case. Examples: "Take Vitamins", "Log Weight"
    "color": String,                     // Required. A hex color code (e.g., "#FF0000").
    "occurrences": [ReminderOccurrence] // Required. When the reminder should occur.
  }

  ReminderOccurrence: {
    "cadenceType": CadenceType,  // Required. How often the reminder repeats.
    "hour": Int,                 // Required. Hour in 24-hour format (0-23).
    "minute": Int,               // Required. Minute of the hour (0-59).
    "daysOfWeek": [Weekday]?     // Optional. Days for weekly reminders.
  }

  CadenceType: An enum with the following cases: \(SocketMessage.CadenceType.stringCaseList())
  
  Weekday: An enum with the following cases: \(SocketMessage.Weekday.stringCaseList())
  """
```

**Key principles:**
- Provide clear descriptions and examples
- Use comments to explain field purposes and constraints
- Reference enum cases dynamically using `stringCaseList()`
- Mark optional fields clearly

#### 3. Update Chat Assistant Prompt (Backend)
Add the new capability to `Backend/Bloom-Backend/Sources/App/Services/AI/Prompts/String+Prompts.swift`:

```swift
// In the chatAssistant prompt string:
If the user wants to set up a reminder for health-related activities (like taking medication, logging weight, drinking water, etc.), you can create reminders for them:
\(String.FunctionSchema.createReminder)
```

**Key principles:**
- Describe when to use the new capability
- Include relevant examples in the description
- Reference the function schema using string interpolation

#### 4. Backend Integration
Add parsing support in `Backend/Bloom-Backend/Sources/App/Services/Chat/ChatServiceV2.swift`:

**a) Add handler method:**
```swift
func handleCreateReminder(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
  if let content = try? decoder.decode(SocketMessage.CreateReminder.self, from: data) {
    return .createReminder(content)
  }
  return nil
}
```

**b) Update parseKind method:**
```swift
if let kind = handleCreateReminder(data: data) {
  return kind
}
```

**c) Add case to RichMessageResponse.Kind enum:**
```swift
case createReminder(SocketMessage.CreateReminder)
```

#### 5. Robust Parsing with Soft Defaults
Implement custom `init(from decoder:)` for AI-generated content to handle parsing errors gracefully:

```swift
public init(from decoder: any Decoder) throws {
  let container = try decoder.container(keyedBy: CodingKeys.self)
  
  // Title with fallback
  self.title = (try? container.decode(String.self, forKey: .title))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Reminder"
  
  // Color validation with fallback
  if let colorString = try? container.decode(String.self, forKey: .color),
     colorString.hasPrefix("#") && colorString.count >= 7 {
    self.color = colorString
  } else {
    self.color = "#007AFF" // Default blue
  }
  
  // Hour/minute validation with clamping
  let rawHour = (try? container.decode(Int.self, forKey: .hour)) ?? 9
  self.hour = max(0, min(23, rawHour))
}
```

**Key principles for soft parsing:**
- Always provide sensible defaults for critical fields
- Validate and clamp numeric values to acceptable ranges
- Trim whitespace from string inputs
- Handle empty arrays appropriately
- Use nil-coalescing (`??`) and optional try (`try?`) patterns
- Follow the patterns established in `SocketMessage.WorkoutPlan` and `SocketMessage.WorkoutSet`

#### 6. Client-Side Rich Content Display
Add support for displaying AI-generated content in the chat UI by updating `ChatRichContentWrapperCell`:

**a) Add state variable:**
```swift
@State private var createReminder: SocketMessage.CreateReminder?
```

**b) Add UI case in body:**
```swift
} else if let createReminder {
  ReminderCell(
    reminder: createReminder.asReminderDTO(),
    occurrence: createReminder.occurrences.first?.asReminderOccurrenceDTO(),
    isCompleted: false  // Hard-coded for display only
  )
  .padding(.leading)
```

**c) Add decoding logic in loadContent():**
```swift
} else if let createReminder = try? JSONDecoder.bloomModel.decode(SocketMessage.CreateReminder.self, from: data) {
  self.createReminder = createReminder
```

**d) Create conversion helpers** in separate extension file:
```swift
extension SocketMessage.CreateReminder {
  func asReminderDTO() -> ReminderDTO {
    // Convert SocketMessage data to DTO for existing UI components
  }
}
```

**Key principles for chat rich content:**
- Reuse existing UI components (like `ReminderCell`) when possible
- Create conversion methods to transform SocketMessage types to app DTOs
- Hard-code display-only properties (like `isCompleted: false`)
- Follow existing padding and layout patterns
- Handle the case in the same pattern as other rich content types

#### 7. Chat History Support
For AI-generated content to appear properly in chat history (after restart or refresh), update the chat history system:

**a) Update ProcessedRichContent enum** in `ChatCellModel.swift`:
```swift
enum ProcessedRichContent: Equatable {
  case goals([ProposedGoal])
  case detectedFood(name: String, meal: FoodItemLog.Meal, servings: [FoodItemServingAmount])
  case createReminder(SocketMessage.CreateReminder)  // Add new case
  // ... other cases
}
```

**b) Update ChatHistoryModifier** in `ChatHistoryModifier.swift`:
Add processing logic in the `processRichContent` method:
```swift
} else if let createReminder = try? JSONDecoder.bloomModel.decode(SocketMessage.CreateReminder.self, from: data) {
  return .createReminder(createReminder)
}
```

**c) Update ChatProcessedRichContentWrapperCell** in `ChatProcessedRichContentWrapperCell.swift`:
Add case to the switch statement:
```swift
case .createReminder(let createReminder):
  ReminderCell(
    reminder: createReminder.asReminderDTO(),
    occurrence: createReminder.occurrences.first?.asReminderOccurrenceDTO(),
    isCompleted: false
  )
```

**Key principles for chat history:**
- Process rich content data in ChatHistoryModifier to avoid async loading in UI
- Use ProcessedRichContent enum to represent pre-processed data
- Reuse the same UI components as live chat for consistency
- Follow the existing switch statement patterns

#### 8. Implementation Considerations
- **Client Integration**: Implement the client-side handling for the new data type
- **Validation**: Additional validation can be added on the client side if needed
- **User Experience**: Soft parsing ensures AI mistakes don't break the user experience
- **Logging**: Consider logging when defaults are used for debugging AI behavior
- **Chat History**: Always update the chat history system to ensure AI-generated content persists across app restarts

This pattern ensures consistent AI integration while maintaining type safety, graceful error handling, persistence across sessions, and clear documentation for the AI model.

#### Deprecated: AssistantSpec Files
**⚠️ IMPORTANT:** The `AssistantSpec+HealthCoach.swift` and `AssistantSpec+HealthGoalSetter.swift` files in the backend are **deprecated and no longer used**. These files were part of an older AI assistant configuration system that has been replaced.

The current AI system uses:
- Function schemas in `String+FunctionSchema.swift`
- Chat prompts in `String+Prompts.swift` 
- Direct function definitions in `Response.Function+Constants.swift`

**Do not update or reference the AssistantSpec files** - they are legacy code that should eventually be removed from the codebase.

This architecture emphasizes:
- **Consistency**: Follow existing patterns
- **Type Safety**: Leverage Swift's type system
- **Performance**: Optimize for smooth user experience
- **Privacy**: Respect user data
- **Maintainability**: Clear organization and naming