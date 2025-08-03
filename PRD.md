# Reminder Side Effects - Product Requirements Document

## Overview

The Reminder Side Effects feature allows users to configure automatic actions that occur when a reminder is completed. This enables workflow automation within Bloom, making it easier to track related health metrics without additional manual steps.

## Feature Objectives

1. **Reduce friction** in logging routine health activities
2. **Automate workflows** by linking reminder completion to health tracking
3. **Improve compliance** by simplifying multi-step health routines
4. **Provide flexibility** through configurable side effect options

## User Stories

### Primary User Stories

1. **As a user taking daily vitamins**, I want to automatically log my vitamin supplement when I complete my "Take Vitamins" reminder, so I don't have to manually track it in nutrition.

2. **As a user tracking hydration**, I want to automatically log 16oz of water when I complete my "Drink Water" reminder, so my hydration tracking is effortless.

3. **As a user with multiple medications**, I want each medication reminder to log the specific medication and dosage, so I have a complete medication history.

### Secondary User Stories

4. **As a user**, I want to configure multiple side effects per reminder, so I can automate complex routines.

5. **As a user**, I want to edit or remove side effects from existing reminders without losing my reminder history.

## Supported Side Effect Types

### Phase 1 (MVP)
1. **Log Food Item**
   - Select specific food item from existing database
   - Configure serving size
   - Specify meal (breakfast, lunch, dinner, snack)

2. **Log Water**
   - Configure amount in oz or ml
   - Quick presets (8oz, 16oz, 24oz, 32oz)

### Phase 2 (Future)
3. **Log Custom Food**
   - Quick nutrition entry (calories, protein, etc.)
   - Name and save for reuse

4. **Start/Stop Habit Timer**
   - Link to existing habits
   - Useful for meditation, reading, etc.

5. **Log Symptom/Mood**
   - Quick symptom tracking
   - Mood scale selection

## Technical Requirements

### Data Model

#### Updated Reminder Model (V23)
```swift
@Model
public final class Reminder {
    // Existing properties...
    
    @Relationship(deleteRule: .cascade, inverse: \ReminderSideEffect.reminder)
    public var sideEffects: [ReminderSideEffect]? = []
}
```

#### New ReminderSideEffect Model
```swift
@Model
public final class ReminderSideEffect {
    public var id = UUID().uuidString
    public var createdDate: Date = Date()
    public var modifiedDate: Date = Date()
    public var type: SideEffectType = .logFood
    public var configuration: Data = Data() // JSON encoded configuration
    public var isEnabled: Bool = true
    
    @Relationship(inverse: \Reminder.sideEffects)
    public var reminder: Reminder?
}

enum SideEffectType: String, Codable, CaseIterable {
    case logFood = "log_food"
    case logWater = "log_water"
    // Future types...
}
```

#### Configuration Structures
```swift
struct LogFoodSideEffectConfig: Codable {
    let foodItemID: String
    let servingSize: Double
    let meal: FoodItemLog.Meal
}

struct LogWaterSideEffectConfig: Codable {
    let amountInOunces: Double
}
```

### UI/UX Requirements

#### Reminder Creation/Edit Flow

1. **Side Effects Section**
   - Appears below reminder scheduling options
   - Collapsible section with "Side Effects" header
   - Shows count of configured side effects when collapsed

2. **Adding Side Effects**
   - "Add Side Effect" button opens sheet/popover
   - Type selection (Food, Water, etc.)
   - Type-specific configuration UI
   - Save/Cancel actions

3. **Managing Side Effects**
   - List shows configured side effects with icons
   - Swipe to delete
   - Tap to edit
   - Toggle to enable/disable

#### Reminder Completion Flow

1. **Execution Feedback**
   - Brief toast/banner showing "Side effects applied"
   - Option to undo for 5 seconds
   - Error handling for failed side effects

2. **Transparency**
   - Small indicator on reminder cell if it has side effects
   - Details visible in reminder detail view

### Implementation Details

#### Side Effect Execution

1. **Timing**
   - Execute immediately after reminder is marked complete
   - Run asynchronously to not block UI
   - Queue multiple side effects for serial execution

2. **Error Handling**
   - Continue with remaining side effects if one fails
   - Log errors for debugging
   - Show user-friendly error message if all fail

3. **Undo Support**
   - Store reference to created records
   - Allow 5-second undo window
   - Clean up created records on undo

#### Data Validation

1. **Food Items**
   - Verify food item still exists before logging
   - Fall back to creating basic entry with name if deleted

2. **Water Amounts**
   - Validate reasonable amounts (1-128 oz)
   - Convert units as needed

## Implementation Plan

### Phase 1: Core Infrastructure
- [ ] Create ReminderSideEffect model and migration
- [ ] Update Reminder model with relationship
- [ ] Create side effect configuration types
- [ ] Implement basic execution engine

### Phase 2: Food & Water Side Effects
- [ ] Build food selection UI component
- [ ] Build water amount configuration UI
- [ ] Integrate with existing food/water logging systems
- [ ] Add execution logic for both types

### Phase 3: UI Integration
- [ ] Add side effects section to CreateEditReminderView
- [ ] Create side effect management UI
- [ ] Add visual indicators to reminder cells
- [ ] Implement execution feedback

### Phase 4: Polish & Testing
- [ ] Add comprehensive preview data
- [ ] Implement undo functionality
- [ ] Add analytics tracking
- [ ] Create onboarding/education flow

## Success Metrics

1. **Adoption Rate**: % of reminders with at least one side effect
2. **Execution Success Rate**: % of side effects that execute without error
3. **User Retention**: Improvement in reminder completion rates
4. **Time Saved**: Reduction in manual logging actions

## Open Questions

1. Should side effects execute if reminder is completed late?
2. Should we support conditional side effects (e.g., only on weekdays)?
3. How do we handle side effects when bulk completing multiple occurrences?
4. Should side effects be shareable between reminders?

## Future Considerations

1. **Templates**: Pre-configured reminder + side effect combinations
2. **Smart Suggestions**: AI-powered side effect recommendations
3. **Automation Rules**: More complex conditional logic
4. **Third-party Integration**: Connect to other health apps/devices

---

## Implementation Tracking

As features are completed, they will be removed from this document. This serves as both a requirements document and a progress tracker.