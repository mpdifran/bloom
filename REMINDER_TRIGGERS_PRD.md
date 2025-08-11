# Reminder Triggers - Product Requirements Document

## Overview
This feature adds automatic reminder completion triggers based on user health data logging. When users log specific health metrics or complete certain workout types, matching reminders will be automatically marked as complete.

## Business Goals
- Reduce friction in reminder completion
- Increase user engagement with health tracking
- Provide smart automation for routine health activities
- Maintain simplicity in the reminder system

## Key Design Decisions

### Mutual Exclusivity
**Reminders can have EITHER triggers OR side effects, but not both.**

Rationale:
- Prevents infinite loops (e.g., water reminder with water side effect triggering another water reminder)
- Keeps the system simple and predictable
- Clear mental model for users

### One Trigger Per Reminder
Each reminder can have at most one trigger type.

Rationale:
- Simplifies UI and user understanding
- Reduces complexity in matching logic
- Aligns with single-purpose reminder philosophy

## Trigger Types

### Health Metrics
1. **Log Weight** (`.logWeight`)
   - Triggered when user logs body weight
   - HealthKit: `HKQuantityType(.bodyMass)`

2. **Log Water** (`.logWater`)
   - Triggered when user logs water intake
   - HealthKit: `HKQuantityType(.dietaryWater)`

3. **Log Blood Pressure** (`.logBloodPressure`)
   - Triggered when user logs blood pressure
   - HealthKit: `HKQuantityType(.bloodPressureSystolic)` and `.bloodPressureDiastolic`

### Workout Types
4. **Log Strength Training** (`.logStrengthTraining`)
   - Triggered by: `Array.strengthTrainingTypes`
   - Includes: Traditional Strength Training, Functional Strength Training, Core Training

5. **Log Cardio** (`.logCardio`)
   - Triggered by: `Array.cardioTypes`
   - Includes: Running, Cycling, Swimming, Elliptical, and many more

6. **Log Mobility & Flexibility** (`.logMobilityFlexibility`)
   - Triggered by: `Array.mobilityAndFlexibilityTypes`
   - Includes: Yoga, Pilates, Flexibility, Barre, Mind and Body, Tai Chi

7. **Log HIIT Workout** (`.logHIIT`)
   - Triggered by: `Array.highIntensityIntervalTrainingTypes`
   - Includes: HIIT, Cross Training, Mixed Cardio, Jump Rope, Kickboxing, Boxing, Step Training

## Trigger Matching Logic

### When Health Data is Logged
1. System observes HealthKit changes via `HKHealthStore.observeChanges`
2. Identifies the trigger type based on the logged data
3. Queries reminders with matching trigger type
4. Filters to today's uncompleted reminders only
5. If multiple matching reminders exist:
   - Selects the reminder occurrence closest to current time
   - Example: If it's 2 PM and there are reminders at 9 AM and 6 PM, the 9 AM reminder is completed
6. Marks the selected reminder as complete
7. Removes associated notifications

### Background Execution
- Triggers work even when app is not active
- Uses HealthKit background delivery
- Ensures reminders complete regardless of app state

## User Interface

### Creating/Editing Reminders
- New "Automatic Trigger" section in reminder creation/edit
- Dropdown/picker to select trigger type
- Clear descriptions of what will trigger completion
- Visual indication of mutual exclusivity with side effects
- When trigger is selected, side effects section is hidden/disabled
- When side effects exist, trigger section is hidden/disabled

### Reminder Display
- Trigger icon/badge on reminder cells
- Different visual treatment for triggered vs manual completion
- Clear indication in reminder details

### User Messaging
- "This reminder will complete automatically when you [trigger action]"
- "Choose either automatic triggers OR side effects for this reminder"
- Warning if user tries to add both

## Technical Implementation

### Data Model (V24)
```swift
// ReminderV24
@Model
final class ReminderV24 {
    // ... existing properties ...
    var triggerType: String? // ReminderTriggerType raw value
}
```

### Key Components
1. **ReminderTriggerType** - Enum defining all trigger types
2. **ReminderTriggerObserver** - Observes HealthKit changes and processes triggers
3. **Updated RemindersManager** - Handles trigger-based queries and validation
4. **Updated UI Components** - Support trigger selection and display

## Edge Cases & Considerations

### Multiple Reminders with Same Trigger
- System selects closest by time
- All matching reminders for the day are eligible
- Only one reminder completes per trigger event

### Retroactive Data Entry
- If user logs data with a past date/time, triggers are not processed
- Only real-time or near-real-time entries trigger completion

### Data Validation
- System validates mutual exclusivity at data layer
- UI prevents invalid configurations
- Migration handles existing reminders (they have no triggers)

## Success Metrics
- Reduction in manual reminder completions
- Increase in reminder completion rate
- User satisfaction with automation
- No reported issues with loops or unexpected behavior

## Future Enhancements (Not in Initial Release)
- Multiple triggers per reminder (OR logic)
- Custom trigger conditions (e.g., "log weight > 150 lbs")
- Trigger history/analytics
- Smart trigger suggestions based on user patterns

## Testing Requirements
1. Each trigger type functions correctly
2. Multiple reminders with same trigger behave correctly
3. Mutual exclusivity is enforced
4. Background triggers work
5. Migration from V23 to V24 succeeds
6. No infinite loops or cascading triggers
7. Notification removal works properly

## Release Notes
"Reminders can now complete automatically! Set triggers for your reminders to mark them complete when you log weight, water, blood pressure, or finish specific workout types. Note: Reminders can have either triggers or side effects, but not both."