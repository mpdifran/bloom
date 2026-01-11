# Health Monitor PRD

> **Status**: Planning
> **Last Updated**: January 9, 2026

---

## Overview

A new **Monitor** tab providing high-level, explainable health insights through three monitors:
1. **Recovery & Sickness Monitor** - Detects early signs of illness or incomplete recovery
2. **Stress & Workout Load Monitor** - Tracks training load balance and chronic stress
3. **Sleep Quality & Rhythm Monitor** - Monitors sleep patterns and circadian rhythm shifts

Each monitor produces a single daily state: **Good**, **Watch**, or **Off**.

---

## Implementation Progress

### Phase 1: Data Layer
- [ ] Create `DailyMetricSample` SwiftData model
- [ ] Build metric fetcher for each HealthKit type (RHR, HRV, sleep, etc.)
- [ ] Implement 7-day and 28-day baseline calculation
- [ ] Implement z-score deviation calculator
- [ ] Create daily aggregation task (runs on app launch / background)
- [ ] **Validate**: Check baseline calculations match expected values

### Phase 2: Detection Engine
- [ ] Define `Signal` struct and corroboration logic
- [ ] Implement persistence rules (2-day requirement for state changes)
- [ ] Build Recovery Monitor state calculator
- [ ] Build Stress Monitor state calculator
- [ ] Build Sleep Monitor state calculator
- [ ] Implement graceful degradation for missing data
- [ ] **Validate**: Manually test state transitions with sample data

### Phase 3: Data Persistence
- [ ] Create `MonitorState` SwiftData model
- [ ] Create `Finding` SwiftData model
- [ ] Create `AlertEvent` SwiftData model
- [ ] Build `MonitorModelActor` for thread-safe access
- [ ] Implement 90-day rolling retention cleanup
- [ ] Create DTOs for all new models
- [ ] **Validate**: Verify data persists across app launches

### Phase 4: Notification System
- [ ] Create `NotificationLevel` enum and preferences storage
- [ ] Implement notification policy engine
- [ ] Build notification content generator
- [ ] Add notification settings UI in Settings
- [ ] Implement per-monitor mute and snooze
- [ ] **Validate**: Test each notification level triggers correctly

### Phase 5: UI Layer
- [ ] Create Monitor tab shell and navigation
- [ ] Build collapsed "All Good" state view
- [ ] Build expanded Watch/Off state cards
- [ ] Create monitor detail view with metrics and charts
- [ ] Add dismiss/snooze action sheet
- [ ] Implement 7-day history chart
- [ ] **Validate**: Walk through all UI states

### Phase 6: AI Integration
- [ ] Define `MonitorAISummaryInput` request model
- [ ] Define `MonitorAISummaryOutput` response model
- [ ] Create backend endpoint for monitor summary
- [ ] Integrate summary into Monitor tab
- [ ] **Validate**: Verify AI generates appropriate non-medical language

---

## Design Decisions

| Decision | Resolution |
|----------|------------|
| Optional sensor data | **Graceful degradation**: Use available sensors, reduce confidence when optional data missing |
| Primary Focus display | **Contextual**: Monitors in Watch/Off expand; Good monitors collapse |
| Today Tab integration | **Separate**: Monitor tab is the dedicated place |
| Notification defaults | **User-configurable**: Off, Off Only (default), Watch+Off, All |

---

## Monitor Specifications

### 1. Recovery & Sickness Monitor

**Purpose**: Detect early physiological signs that suggest the body is fighting something.

**Metrics Used:**
| Metric | HealthKit Type | Baseline | Required? |
|--------|----------------|----------|-----------|
| Resting Heart Rate | `.restingHeartRate` | 28-day | Yes |
| Heart Rate Variability | `.heartRateVariabilitySDNN` | 28-day | Yes |
| Wrist Temperature | `.appleSleepingWristTemperature` | 14-day | No (Series 8+) |
| Respiratory Rate | `.respiratoryRate` | 14-day | No |

**State Rules:**
| State | Criteria |
|-------|----------|
| Good | All deviations within ±1.0 z-score |
| Watch | 1-2 signals at 1.0-2.0 z-score for 2+ days |
| Off | 2+ signals >2.0 z-score OR high-confidence pattern for 2+ days |

**Example Findings:**
- "Your resting heart rate is higher than usual" (RHR +1.5 z-score)
- "Elevated wrist temperature during sleep" (temp +0.3°C with elevated RHR)

---

### 2. Stress & Workout Load Monitor

**Purpose**: Track training load balance and detect overtraining.

**Metrics Used:**
| Metric | HealthKit Type | Baseline | Required? |
|--------|----------------|----------|-----------|
| Active Energy | `.activeEnergyBurned` | 7-day & 28-day | Yes |
| Workouts | `HKWorkout` | 7-day & 28-day | No |
| HRV | `.heartRateVariabilitySDNN` | 28-day | No |
| Heart Rate Recovery | `.heartRateRecoveryOneMinute` | 28-day | No |

**Key Calculation:**
```
Acute:Chronic Ratio = (7-day load) / (28-day avg × 7)
```

**State Rules:**
| State | Criteria |
|-------|----------|
| Good | Ratio 0.8-1.3, HRV stable |
| Watch | Ratio 1.3-1.5 OR <0.8 OR HRV declining 5-15% |
| Off | Ratio >1.5 OR HRV >15% decline for 3+ days |

---

### 3. Sleep Quality & Rhythm Monitor

**Purpose**: Track sleep patterns and circadian rhythm disruptions.

**Metrics Used:**
| Metric | HealthKit Type | Baseline | Required? |
|--------|----------------|----------|-----------|
| Sleep Duration | `.sleepAnalysis` | 7-day & 28-day | Yes |
| Sleep Stages | `.sleepAnalysis` | 7-day | No |
| Bedtime/Wake Time | Derived | 7-day | No |

**State Rules:**
| State | Criteria |
|-------|----------|
| Good | Duration ±1 z-score, efficiency >0.85, variability <60min |
| Watch | Duration declining OR efficiency 0.75-0.85 OR variability 60-90min |
| Off | Duration very low for 3+ days OR efficiency <0.75 OR variability >90min |

---

## Data Model

### Core Entities

```swift
@Model
final class DailyMetricSample {
  @Attribute(.unique) var id: String  // "{date}_{metricType}"
  var date: Date
  var metricType: String
  var value: Double
  var quality: String  // "complete", "partial", "sparse"
  var baseline7Day: Double?
  var baseline28Day: Double?
  var zScore: Double?
}

@Model
final class MonitorState {
  @Attribute(.unique) var id: String  // "{date}_{monitorType}"
  var date: Date
  var monitorType: String  // "recovery", "stress", "sleep"
  var stateRawValue: String  // "good", "watch", "off", "unavailable"
  var confidence: Double
  var daysInCurrentState: Int

  @Relationship(deleteRule: .cascade)
  var findings: [Finding]?
}

@Model
final class Finding {
  @Attribute(.unique) var id: String
  var date: Date
  var title: String
  var explanation: String
  var confidenceRawValue: String  // "high", "medium", "low"
  var isDismissed: Bool = false

  @Relationship(inverse: \MonitorState.findings)
  var monitorState: MonitorState?
}

@Model
final class AlertEvent {
  @Attribute(.unique) var id: String
  var date: Date
  var monitorType: String
  var eventTypeRawValue: String
  var notificationSent: Bool
}
```

---

## Notification Preferences

**User can choose notification sensitivity:**

| Level | Good→Watch | Watch→Off | Off→Good |
|-------|------------|-----------|----------|
| Off | — | — | — |
| Off Only (default) | — | ✓ | — |
| Watch and Off | ✓ | ✓ | — |
| All changes | ✓ | ✓ | ✓ |

**Additional Controls:**
- Mute individual monitors
- Snooze all for 24h / 48h / 1 week
- Max 1 notification per day

---

## UX: Monitor Tab States

### All Good (Collapsed)
```
┌─────────────────────────────────────┐
│  ✓ Everything looks good            │
│  ┌─────────────────────────────┐    │
│  │ 😌 Recovery ✓  💪 Load ✓    │    │
│  │ 😴 Sleep ✓                  │    │
│  └─────────────────────────────┘    │
│  Last updated: Today, 6:00 AM       │
└─────────────────────────────────────┘
```

### Watch/Off (Prominent)
```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────┐    │
│  │ 🔶 Recovery         Watch   │    │
│  │                             │    │
│  │ Your resting heart rate     │    │
│  │ has been elevated for 2 days│    │
│  │                             │    │
│  │ [See Details]  [Dismiss]    │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 💪 Load ✓    😴 Sleep ✓     │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## Language Guidelines

**Use confidence-aware, non-medical language:**

| Instead of... | Use... |
|---------------|--------|
| "Warning: elevated heart rate" | "Your resting heart rate is higher than usual" |
| "Sleep deficiency detected" | "You've been getting less sleep than your usual" |
| "Risk of overtraining" | "Your training load has spiked recently" |

**Explanation Template:**
> "{What we noticed} — {How long} — {What it might mean} — {What you might do}"

---

## AI Summary Boundaries

**AI MUST:**
- Use only structured data provided (never raw HealthKit)
- Generate summaries in plain, non-medical language
- Reference "your usual" rather than population norms

**AI MUST NOT:**
- Diagnose conditions
- Use clinical terminology (risk, symptom, condition)
- Make illness progression predictions
- Override on-device state determination

---

## Open Questions

1. **Onboarding**: How many days of data before activating? (Proposal: 7 days)
2. **Watch App**: Surface on Apple Watch complication?
3. **Historical Context**: Show "last month you were..." comparisons?

---

## Files to Create/Modify

**New Files (CoreHealth):**
- `Monitors/DailyMetricSample.swift`
- `Monitors/MonitorCalculator.swift`
- `Monitors/RecoveryMonitor.swift`
- `Monitors/StressMonitor.swift`
- `Monitors/SleepMonitor.swift`

**New Files (DataContainer):**
- `Schema/V31/MonitorStateV31.swift`
- `Schema/V31/FindingV31.swift`
- `Schema/V31/AlertEventV31.swift`
- `DTOs/MonitorStateDTO.swift`
- `ModelActors/MonitorModelActor.swift`

**New Files (UserInterface):**
- `Monitor/MonitorView.swift`
- `Monitor/MonitorViewModel.swift`
- `Monitor/Components/MonitorCard.swift`
- `Monitor/Components/MonitorDetailView.swift`
- `Monitor/Components/MonitorHistoryChart.swift`

**Modified Files:**
- `TabController.swift` (add Monitor tab)
- `RootView.swift` (add Monitor tab)
- `SettingsView.swift` (add notification preferences)
