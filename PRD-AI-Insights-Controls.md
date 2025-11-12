# PRD: AI Today Insights Privacy Controls

**Status:** Planning
**Last Updated:** 2025-11-10
**Owner:** Mark DiFranco

## Overview

Add privacy controls for AI-generated today insights with granular health data category selection. Users can control AI insights through Today Settings, with an overall enable/disable toggle and detailed category controls.

## Goals

1. Give users explicit control over AI insights generation via settings
2. Provide granular privacy controls for health data sharing
3. Default to disabled - users must opt in
4. Simple, clear settings UI

## Requirements

### 1. Data Model Layer

#### Create `AIInsightsSettings.swift` in BloomUI
```swift
public struct AIInsightsSettings: Codable {
    public var isEnabled: Bool // defaults to false
    public var enabledCategories: Set<AIHealthCategory> // all enabled by default
}
```
- Stored via `@AppStorage` similar to `TodaySettingsStorage`
- Key: `"AIInsights.settings"`

#### Create `AIHealthCategory.swift` enum
Grouped health data categories:

**Health Categories:**
- Physical Activity (activity, exercise, training load)
- Body Metrics (body composition, heart health)
- Mental Wellness (stress, mindfulness)
- Sleep
- Nutrition
- Digestive Health
- Menstrual Health (female users only)

**Other Data:**
- Demographics (age, sex, etc.)
- Goals (goal progress)
- Weather
- Calendar Events

Each category includes:
- `displayName: String`
- `icon: SFSymbol`
- `description: String`
- `mappedVitals: [VitalType]` - maps to fields in DayVitalsData

### 2. UI Components Layer

#### Create `AIInsightsTodaySettingsView.swift`
Granular category selection view

**Layout:**
- NavigationStack with title "Data Shared with AI"
- Section "Health Data" with health category toggles
- Section "Other Data" with non-health category toggles
- Each row: icon, name, description, toggle

**Behavior:**
- Auto-save on toggle change
- Hide Menstrual Health category for male users
- If all categories disabled, show warning alert

#### Update `TodaySettingsView.swift`
Add AI Insights section as FIRST section (above Calendars)

**Section: "AI Insights"**

Cell 1: Toggle Cell (always visible)
- Label: "AI Insights"
- Subtitle: "Personalized insights from your health data"
- Toggle switch (trailing)
- When toggled off: Show confirmation alert
- When toggled on: Trigger insights refresh if needed

Cell 2: Detail Cell (only when toggle ON)
- Label: "Data Shared with AI"
- Subtitle: "8 categories selected" (dynamic count)
- Disclosure indicator
- Navigates to `AIInsightsTodaySettingsView`

### 3. Manager Layer

#### Update `TodayInsightsManager.swift`

**Changes:**
```swift
func shouldRefreshContent() -> Bool {
    // Early return if insights disabled
    guard AIInsightsSettings.shared.isEnabled else { return false }

    // Existing logic...
}

private func loadTodayContent() async {
    guard AIInsightsSettings.shared.isEnabled else { return }

    // Pass enabled categories to calculator
    let enabledCategories = AIInsightsSettings.shared.enabledCategories
    let healthContext = try await DayReviewCalculator.shared
        .calculateDayReviewHealthDataString(
            for: yesterday,
            enabledCategories: enabledCategories
        )

    // Existing logic...
}
```

#### Update `DayReviewCalculator.swift`

**New Signature:**
```swift
func calculateDayReviewHealthData(
    for date: Date,
    enabledCategories: Set<AIHealthCategory>? = nil
) async throws -> DayReviewHealthData
```

**Category Filtering Logic:**
When `enabledCategories` is provided, filter fields based on category mappings:

| Category | Filtered Fields |
|----------|----------------|
| Physical Activity | vitals.activity, vitals.exercise, vitals.trainingLoad |
| Body Metrics | vitals.bodyComposition, vitals.heartHealth |
| Mental Wellness | vitals.stress, vitals.mindfulness |
| Sleep | vitals.sleep |
| Nutrition | vitals.nutrition |
| Digestive Health | vitals.digestiveHealth |
| Menstrual Health | vitals.menstrualHealth |
| Demographics | demographics |
| Goals | goalProgress |
| Weather | weather, simplifiedWeather |
| Calendar Events | events |

Set filtered-out fields to `nil` in returned `DayReviewHealthData`.

## Implementation Plan

### Phase 1: Data Models & Settings ✅
- [ ] Create `AIInsightsSettings.swift` in BloomUI
- [ ] Create `AIHealthCategory.swift` enum
- [ ] Add property wrapper for AppStorage
- [ ] Unit tests for settings persistence

### Phase 2: Settings UI ✅
- [ ] Create `AIInsightsTodaySettingsView.swift`
- [ ] Update `TodaySettingsView.swift` with AI Insights section
- [ ] Add toggle cell with confirmation alert
- [ ] Add detail navigation cell (conditional visibility)
- [ ] Add category count subtitle
- [ ] Test settings flow

### Phase 3: Manager Updates ✅
- [ ] Update `TodayInsightsManager.swift` to check settings
- [ ] Update `DayReviewCalculator.swift` with category filtering
- [ ] Add category-to-vitals mapping logic
- [ ] Test filtering with various category combinations
- [ ] Test insights load trigger from settings toggle

### Phase 4: Testing & Polish ✅
- [ ] Manual testing: Toggle insights on/off
- [ ] Manual testing: Category selection
- [ ] Manual testing: Female/male category visibility
- [ ] Manual testing: All categories disabled
- [ ] Add telemetry events
- [ ] Code review
- [ ] QA testing

## Files to Create
1. `Apps/Bloom/BloomUI/Settings/AIInsightsSettings.swift`
2. `Apps/Bloom/BloomUI/Settings/AIHealthCategory.swift`
3. `Apps/Bloom/Bloom/UserInterface/Today/Settings/AIInsightsTodaySettingsView.swift`

## Files to Modify
1. `Apps/Bloom/Bloom/UserInterface/Today/Settings/TodaySettingsView.swift`
2. `Apps/Bloom/Bloom/HealthManager/TodayInsightsManager.swift`
3. `Apps/Bloom/Bloom/UserInterface/Reports/MorningReport/Calculators/DayReviewCalculator.swift`

## User Flows

### Enable AI Insights Flow
1. User opens Today Settings
2. Sees "AI Insights" section at top
3. Toggle is OFF by default
4. Taps toggle to turn ON
5. "Data Shared with AI" cell appears below
6. Insights begin loading in background
7. Returns to Today view to see insights

### Customize Categories Flow
1. User has AI Insights enabled
2. Opens Today Settings
3. Taps "Data Shared with AI" cell
4. Sees list of all categories with toggles
5. Disables specific categories (e.g., Mental Wellness)
6. Changes auto-save
7. Returns - next insight refresh uses new settings

### Disable AI Insights Flow
1. User opens Today Settings
2. Taps AI Insights toggle to turn OFF
3. Confirmation alert appears
4. Confirms disable
5. "Data Shared with AI" cell disappears
6. Insights stop generating

## Settings UI Flow
```
TodaySettingsView
├── AI Insights Section (NEW - FIRST SECTION)
│   ├── [Toggle: AI Insights] (always visible)
│   └── [Data Shared with AI →] (only when toggle ON) → AIInsightsTodaySettingsView
│       ├── Health Data Section
│       │   ├── Physical Activity toggle
│       │   ├── Body Metrics toggle
│       │   ├── Mental Wellness toggle
│       │   ├── Sleep toggle
│       │   ├── Nutrition toggle
│       │   ├── Digestive Health toggle
│       │   └── Menstrual Health toggle (female only)
│       └── Other Data Section
│           ├── Demographics toggle
│           ├── Goals toggle
│           ├── Weather toggle
│           └── Calendar Events toggle
├── Calendars Section
│   └── [Calendars cell] → CalendarSelectionView
├── Phases Section
│   └── [Time mode cells...]
└── Sections Section
    └── [Section toggles...]
```

## Telemetry Events

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `AI Insights Enabled` | `source: "settings"` | Toggle switched ON |
| `AI Insights Disabled` | - | Toggle switched OFF |
| `AI Insights Categories Updated` | `enabledCount: Int` | Category selection changed |
| `AI Insights Category Settings Opened` | - | Navigated to detail view |

## Edge Cases & Considerations

1. **All categories disabled**: Show warning alert, but allow it
2. **Female → Male sex change**: Hide menstrual health category, auto-disable it if enabled
3. **Network failure during load**: Existing error handling covers this
4. **Settings changes during load**: Cancel in-flight request, start new one with updated categories
5. **Widget updates**: Widgets respect the same settings (won't show insights if disabled)
6. **Default state**: All users start with `isEnabled = false`, must explicitly opt in

## Success Metrics

- Opt-in rate for AI insights (% of users who enable)
- Settings engagement (% of users who customize categories)
- Category selection patterns (which categories are most/least enabled)

## Open Questions

- [ ] Should we show a primer/education screen when toggling ON for first time?
- [ ] Should we allow insights to run with zero categories enabled?
- [ ] What copy should we use in the confirmation alert when disabling?

## Future Enhancements

- Per-category explanations of how data is used
- Data transparency: Show last time insights were generated and what data was sent
- Export/delete AI interaction history
