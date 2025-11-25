# Year In Bloom - Product Requirements Document

## Overview

**Feature Name:** Year In Bloom
**Inspired By:** Spotify Wrapped
**Goal:** Provide users with an engaging, shareable annual summary of their health and wellness journey through Bloom
**Initial Scope:** Workout statistics (MVP)
**Version:** 1.0
**Last Updated:** 2024-11-24

---

## Product Vision

Year In Bloom celebrates users' health achievements over the past year by presenting personalized statistics in a visually engaging, swipeable card format. Similar to Spotify Wrapped, this feature aims to:

- **Celebrate progress** - Highlight user achievements and milestones
- **Increase engagement** - Create an annual tradition users look forward to
- **Drive retention** - Encourage continued tracking into the new year
- **Social sharing** - Enable users to share their health wins (future)
- **Comprehensive view** - Touch on all aspects of health tracked in Bloom

---

## Availability Window

**When:** December 15 - January 31

**Logic:**
- **Dec 15 - Dec 31**: Show current year's stats (allows users to preview their year before it ends)
- **Jan 1 - Jan 31**: Show previous year's stats (e.g., in Jan 2025, show 2024)
- **Outside this window**: Feature is not accessible

**Rationale:**
- Gives users 2+ weeks to preview their year-end stats
- Full month of January to view and share their complete year
- Creates urgency and FOMO (limited-time availability)

---

## Phase 1: Workout Statistics (MVP)

### Card 1: Workout Frequency Rankings

**Title:** "Your Most Frequent Workouts"

**Content:**
- Display **ALL** workout types the user performed in the year
- Ranked by frequency (number of times performed)
- Format: Workout icon + name + count

**Layout:**
- Scrollable vertical list (may exceed screen height)
- Horizontal bar chart visualization showing relative frequency
- Card itself is part of horizontal swipe navigation

**Example:**
```
🏃 Running                    127 workouts
🚴 Cycling                    89 workouts
🏋️ Strength Training          67 workouts
🧘 Yoga                       45 workouts
🏊 Swimming                   23 workouts
⚽ Soccer                      12 workouts
```

---

### Card 2: Workout Duration Rankings

**Title:** "Workouts by Time Spent"

**Content:**
- Display **ALL** workout types the user performed
- Ranked by total duration (summed across all workouts of that type)
- Format: Workout icon + name + total time

**Layout:**
- Scrollable vertical list
- Horizontal bar chart showing relative duration
- Display format: "X hours Y minutes" or "X minutes" for <1 hour

**Example:**
```
🚴 Cycling                    87 hours 23 min
🏃 Running                    62 hours 45 min
🏋️ Strength Training          34 hours 12 min
🧘 Yoga                       28 hours 30 min
🏊 Swimming                   15 hours 8 min
```

---

### Card 3: Total Calories Burned

**Title:** "Total Calories Burned"

**Content:**
- Large, prominent display of total active calories burned
- Single fun comparison analogy scaled to the total

**Layout:**
- Big number animation on card appear
- Comparison text below with emoji
- Clean, minimal design - let the number shine

**Calorie Comparison Tiers:**

| Calorie Range | Example Comparisons |
|---------------|-------------------|
| < 50,000 | "Enough to boil X kettles" <br> "Power a laptop for X days" |
| 50,000 - 150,000 | "Heat a hot tub X times" <br> "Power your home for X days" <br> "Charge X smartphones for a year" |
| 150,000+ | "Charge X electric cars" <br> "Power a city block for X hours" <br> "Run a refrigerator for X months" |

**Selection Logic:** Pick single most impressive/appropriate comparison based on total

**Example:**
```
🔥 142,567 kcal

Enough to power your home for 6 days!
```

---

### Card 4: Distance Breakdown

**Title:** "Distance Covered"

**Content:**
- Show distance totals for Walking, Running, and Cycling
- **Only show categories with non-zero values**
- Optional: Creative comparison for total distance

**Layout:**
- Clean list of distance types with icons
- Display in user's preferred units (km or miles)
- Possible map visualization showing equivalent journey

**Display Rules:**
- If user only ran: Show only running distance
- If user ran and cycled: Show both
- If user did all three: Show all three

**Example (all three activities):**
```
🚶 Walking: 847 km
🏃 Running: 1,243 km
🚴 Cycling: 2,891 km

Total: 4,981 km
You could have traveled from San Francisco to New York!
```

**Example (only running):**
```
🏃 Running: 1,243 km

You could have run from Boston to Miami!
```

---

## User Experience Flow

### Entry Point
- TBD: Prominent banner/card in app during availability window
- Possible locations: Home screen, Profile tab, Settings

### Navigation
1. User taps "View Your Year In Bloom"
2. Loading screen appears with progress indicator
3. Compilation happens (5-10 seconds for first time)
4. Transition to first card with animation

### Card Interaction
- **Swipe horizontally** to move between cards (4 total)
- **Scroll vertically** within cards (for long workout lists)
- Page indicators at bottom show position (1 of 4)
- Smooth animations between cards

### Caching
- **First View:** Compile from HealthKit data, show loading screen
- **Cached:** If viewed during Dec 15 - Jan 31 window, stats are saved to UserDefaults
- **Subsequent Views:** Instant load from cache
- **No Manual Refresh:** Once compiled, stats are frozen (ensures consistency)

---

## Technical Architecture

### Directory Structure

```
CoreHealth/YearInBloom/
├── YearInBloomCalculator.swift       # Actor that compiles stats
├── YearInBloomWorkoutStats.swift     # Data models (Codable)
└── CalorieComparisons.swift          # Comparison selection logic

Apps/Bloom/Bloom/UserInterface/YearInBloom/
├── YearInBloomView.swift             # Main container (TabView)
├── YearInBloomViewModel.swift        # Observable ViewModel
└── Cards/
    ├── WorkoutFrequencyCard.swift    # Card 1
    ├── WorkoutDurationCard.swift     # Card 2
    ├── CaloriesTotalCard.swift       # Card 3
    └── DistanceBreakdownCard.swift   # Card 4
```

---

### Data Model

**File:** `CoreHealth/YearInBloom/YearInBloomWorkoutStats.swift`

```swift
public struct YearInBloomWorkoutStats: Codable, Sendable, Hashable {
    let year: Int
    let compiledDate: Date

    // Rankings
    let workoutsByFrequency: [WorkoutTypeStat]
    let workoutsByDuration: [WorkoutTypeStat]

    // Totals
    let totalCalories: Double
    let calorieComparisonText: String

    // Distances (optional - only if > 0)
    let walkingDistanceKm: Double?
    let runningDistanceKm: Double?
    let cyclingDistanceKm: Double?
    let totalDistanceKm: Double?
    let distanceComparisonText: String?
}

public struct WorkoutTypeStat: Codable, Sendable, Hashable {
    let activityType: UInt // HKWorkoutActivityType raw value
    let activityName: String // Human-readable name
    let count: Int
    let totalDurationSeconds: TimeInterval
}
```

---

### Calculator Actor

**File:** `CoreHealth/YearInBloom/YearInBloomCalculator.swift`

**Responsibilities:**
1. Fetch all workouts for a given year using `HealthStoreFetcher.shared`
2. Aggregate data by workout type
3. Calculate rankings and totals
4. Select appropriate calorie comparison
5. Filter non-zero distances
6. Save to UserDefaults (during cache window only)
7. Retrieve cached stats

**Key Methods:**
```swift
public final actor YearInBloomCalculator {
    public static let shared = YearInBloomCalculator()

    // Fetch from UserDefaults cache
    public func fetchCachedStats(for year: Int) -> YearInBloomWorkoutStats?

    // Compile from HealthKit
    public func compileStats(for year: Int) async throws -> YearInBloomWorkoutStats

    // Check if we should cache
    private func shouldCache(for year: Int) -> Bool

    // Save to UserDefaults
    private func saveStats(_ stats: YearInBloomWorkoutStats)
}
```

**UserDefaults Key Format:** `"YearInBloom.workoutStats.{year}"`
Example: `"YearInBloom.workoutStats.2024"`

---

### Cache Window Logic

**Cache Stats When:**
- Current date is between Dec 15 of target year and Jan 31 of following year

**Implementation:**
```swift
private func shouldCache(for year: Int) -> Bool {
    let now = Date()
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)

    // Dec 15-31 of target year
    if currentYear == year && currentMonth == 12 && currentDay >= 15 {
        return true
    }

    // Jan 1-31 of following year
    if currentYear == year + 1 && currentMonth == 1 && currentDay <= 31 {
        return true
    }

    return false
}
```

**Stop calculating after:** Jan 31st of the following year (stats are "frozen")

---

### ViewModel

**File:** `Apps/Bloom/Bloom/UserInterface/YearInBloom/YearInBloomViewModel.swift`

**Responsibilities:**
1. Determine which year to show (current or previous)
2. Check cache first
3. Trigger compilation if needed
4. Manage loading state
5. Handle errors

**Key Properties:**
```swift
@Observable
final class YearInBloomViewModel {
    var stats: YearInBloomWorkoutStats?
    var isLoading = false
    var error: Error?
    var currentCardIndex = 0
}
```

**Year Determination Logic:**
```swift
private func determineTargetYear() -> Int {
    let now = Date()
    let calendar = Calendar.current
    let month = calendar.component(.month, from: now)
    let year = calendar.component(.year, from: now)

    // January: Show previous year
    if month == 1 {
        return year - 1
    }

    // December (15-31): Show current year
    return year
}
```

---

### View Structure

**Main View:** `YearInBloomView.swift`
- Uses `TabView` with `PageTabViewStyle` for horizontal swiping
- Contains 4 card views
- Shows page indicators
- Handles loading state (full-screen progress indicator)

**Card Views:**
- Each card is a separate SwiftUI view
- Receives relevant data from parent
- Handles own layout and scrolling
- Consistent styling (background, padding, typography)

---

### Data Sources

**Primary:** `HealthStoreFetcher.shared`

**Methods Used:**
```swift
// Fetch all workouts for year
let workouts = await HealthStoreFetcher.shared.fetchWorkouts(
    dateRange: DateRange.year(year)
)

// Or use workout summations if available
let summations = await HealthStoreFetcher.shared.fetchWorkoutSummations(
    dateRange: DateRange.year(year)
)
```

**Aggregation:**
- Group workouts by `HKWorkoutActivityType`
- Sum durations using `workout.duration`
- Sum calories using `totalEnergyBurned` quantity
- Sum distances using `totalDistance` quantity (filtered by workout type)

---

## Calorie Comparison Examples

### Low Tier (< 50,000 kcal)
- "Boil 487 kettles of water"
- "Power a laptop for 83 days"
- "Charge 12,500 smartphones"

### Medium Tier (50,000 - 150,000 kcal)
- "Heat a hot tub 15 times"
- "Power your home for 6 days"
- "Run a washing machine 450 times"
- "Charge 25,000 smartphones"

### High Tier (150,000+ kcal)
- "Charge 4 electric cars fully"
- "Power a city block for 12 hours"
- "Run a refrigerator for 8 months"
- "Drive an electric car 1,200 miles"

**Selection Criteria:**
1. Scale appropriately to user's total
2. Choose relatable, everyday items
3. Prefer impressive but believable comparisons
4. Rotate comparisons for returning users (future enhancement)

---

## Distance Mapping Examples

**Creative Comparisons:**
- Use user's location to show "You could have run from [Current City] to [Destination City]"
- Fall back to famous routes: "Run from NYC to DC", "Cycle across California"
- Milestone distances: "Half the length of the Great Wall of China"

**Implementation Note:** Start with static comparisons, add geo-location based ones later

---

## Future Enhancements (Not in MVP)

### Additional Health Sections
Following the same card pattern, add sections for:

1. **Nutrition Journey**
   - Total meals logged
   - Most logged foods
   - Macro balance achievements
   - Water intake total

2. **Sleep Story**
   - Total hours slept
   - Best sleep month
   - REM/Deep sleep totals
   - Sleep consistency score

3. **Body Transformation**
   - Weight change journey
   - Body composition improvements
   - Goal achievements

4. **Heart Health**
   - Resting heart rate evolution
   - HRV improvements
   - VO2 Max gains

5. **AI Companion Stats**
   - Chat messages sent
   - Insights received
   - Most discussed topics

6. **Habit Mastery**
   - Goals achieved
   - Longest streaks
   - Most improved vital

### Social Sharing
- Export individual cards as images
- Share to Instagram, Twitter, etc.
- Bloom-branded graphics

### Customization
- Choose which stats to share
- Select color themes
- Add personal notes/reflections

### Gamification
- Badges for milestones
- Year-over-year comparisons
- Community leaderboards (opt-in, anonymous)

---

## Design Guidelines

### Visual Style
- **Clean and modern** - Let data be the hero
- **Bloom brand colors** - Use existing app palette
- **Animations** - Smooth transitions, number count-ups
- **Typography** - Large numbers, readable comparisons

### Card Design
- **Full screen** - Immersive experience
- **Scrollable within cards** - For long lists
- **Consistent structure** - Title, visual, data, insight
- **Page indicators** - Show progress (1 of 4)

### Accessibility
- VoiceOver support for all stats
- Dynamic Type support
- High contrast mode
- Haptic feedback on card transitions

---

## Technical Considerations

### Performance
- **First Load:** 5-10 seconds to compile stats (acceptable)
- **Cached Load:** Instant (<1 second)
- **Memory:** Keep stats in memory during session, reload from UserDefaults on app restart
- **Background Compilation:** Consider pre-computing on Dec 15 (future enhancement)

### Error Handling
- **HealthKit Permission Denied:** Show helpful message with link to Settings
- **No Workout Data:** Show encouraging message to start tracking
- **Calculation Errors:** Graceful fallback, log to telemetry

### Data Privacy
- **All data stays on device** (UserDefaults, HealthKit)
- **No server storage** (initially)
- **User controls sharing** (when that feature is added)

### Testing
- **Unit Tests:** Calculator logic, aggregation, comparisons
- **UI Tests:** Card swiping, scrolling, loading states
- **Manual Testing:** Various data volumes (few workouts vs hundreds)

---

## Success Metrics

### Engagement
- % of users who view Year In Bloom during window
- Average time spent viewing
- Cards viewed per session
- Return visits during January

### Retention
- App usage in February (post-Year In Bloom) vs baseline
- User churn rate comparison
- New tracking behavior (do users track more after seeing stats?)

### Sharing (Future)
- Social shares per user
- Share completion rate
- External traffic from shares

---

## Open Questions & Decisions Needed

- [ ] Where should entry point be? (Home screen? Profile?)
- [ ] Should we show notification when Year In Bloom becomes available?
- [ ] Brand assets: Logo, custom illustrations for cards?
- [ ] Telemetry events to track?
- [ ] Localization: Translate comparison text?
- [ ] Units: Always use user's locale preferences?

---

## Implementation Phases

### Phase 1: MVP (This Document)
- [ ] Build data layer (Calculator, Models)
- [ ] Create 4 workout cards
- [ ] Implement caching logic
- [ ] Add loading states
- [ ] Basic testing

### Phase 2: Polish
- [ ] Animations and transitions
- [ ] Custom illustrations
- [ ] Accessibility audit
- [ ] Edge case handling
- [ ] Comprehensive testing

### Phase 3: Expansion
- [ ] Additional health sections
- [ ] Social sharing
- [ ] Multi-year support
- [ ] Personalization

---

## Appendix: HKWorkoutActivityType Reference

Common workout types to handle:

| Activity Type | Icon | Display Name |
|--------------|------|--------------|
| `.running` | 🏃 | Running |
| `.walking` | 🚶 | Walking |
| `.cycling` | 🚴 | Cycling |
| `.swimming` | 🏊 | Swimming |
| `.yoga` | 🧘 | Yoga |
| `.functionalStrengthTraining` | 🏋️ | Strength Training |
| `.traditionalStrengthTraining` | 💪 | Strength Training |
| `.highIntensityIntervalTraining` | ⚡ | HIIT |
| `.soccer` | ⚽ | Soccer |
| `.basketball` | 🏀 | Basketball |
| `.elliptical` | 🎯 | Elliptical |
| `.stairClimbing` | 🪜 | Stair Climbing |

See [Apple's HKWorkoutActivityType documentation](https://developer.apple.com/documentation/healthkit/hkworkoutactivitytype) for complete list.

---

**Document End**
