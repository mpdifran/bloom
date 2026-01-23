//
//  NotificationSettingsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import AppUI
import BloomUI
import SFSafeSymbols

struct NotificationSettingsView: View {

  @ObservedObject private var preferences = NotificationPreferences.shared
  @ObservedObject private var monitorPreferences = MonitorNotificationPreferences.shared

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        workoutSection
        goalSection
        monitorSection
      }
      .navigationTitle("Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .presentationDragIndicator(.visible)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
  }

  // MARK: - Workout Section

  private var workoutSection: some View {
    VStack {
      SectionTitleView("Workouts")
        .padding(.horizontal)

      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Workout Completion")
            .font(.body)
            .fontWeight(.medium)

          Text("Get notified of analysis when workouts finish")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Toggle("", isOn: $preferences.workoutCompletionEnabled)
          .labelsHidden()
      }
      .cardContainer()
    }
  }

  // MARK: - Goal Section

  private var goalSection: some View {
    VStack {
      SectionTitleView("Goals")
        .padding(.horizontal)

      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Goal Achievements")
            .font(.body)
            .fontWeight(.medium)

          Text("Celebrate when you hit your goals")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Toggle("", isOn: $preferences.goalAchievementsEnabled)
          .labelsHidden()
      }
      .cardContainer()
    }
    .padding(.top, 16)
  }

  // MARK: - Monitor Section

  private var monitorSection: some View {
    VStack {
      SectionTitleView("Health Monitors")
        .padding(.horizontal)

      VStack(spacing: 8) {
        ForEach(MonitorType.allCases, id: \.self) { monitorType in
          monitorRow(for: monitorType)
            .cardContainer()
        }
      }

      Text("Get notified when a health monitor needs your attention.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
        .padding(.horizontal)
        .padding(.top, 4)
    }
    .padding(.top, 16)
  }

  // MARK: - Monitor Row

  private func monitorRow(for monitorType: MonitorType) -> some View {
    let isActive = monitorPreferences.isEnabled(for: monitorType) || monitorPreferences.isSnoozed(for: monitorType)

    return HStack(spacing: 12) {
      Image(systemSymbol: monitorIcon(for: monitorType))
        .font(.title3)
        .foregroundStyle(monitorColor(for: monitorType))
        .saturation(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(monitorType.displayName)
          .font(.body)
          .fontWeight(.medium)

        statusSubtitle(for: monitorType)
      }

      Spacer()

      statusMenu(for: monitorType)
    }
  }

  @ViewBuilder
  private func statusSubtitle(for monitorType: MonitorType) -> some View {
    if monitorPreferences.isSnoozed(for: monitorType),
       let snoozedUntil = monitorPreferences.snoozedUntil(for: monitorType) {
      Text(daysRemainingText(until: snoozedUntil))
        .font(.caption)
        .foregroundStyle(.orange)
    } else if !monitorPreferences.isEnabled(for: monitorType) {
      Text("Disabled")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      EmptyView()
    }
  }

  private func daysRemainingText(until date: Date) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day], from: Date(), to: date)
    let days = max(0, components.day ?? 0)

    if days == 0 {
      return "Less than 1 day remaining"
    } else if days == 1 {
      return "1 day remaining"
    } else {
      return "\(days) days remaining"
    }
  }

  private func statusMenu(for monitorType: MonitorType) -> some View {
    Menu {
      Button {
        monitorPreferences.clearSnooze(for: monitorType)
        monitorPreferences.setEnabled(true, for: monitorType)
      } label: {
        Label("Turn On", systemSymbol: .bell)
      }

      Divider()

      ForEach(MonitorNotificationPreferences.SnoozeDuration.allCases, id: \.self) { duration in
        Button {
          monitorPreferences.snooze(monitorType, for: duration.timeInterval)
        } label: {
          Label("Snooze for \(duration.displayName)", systemSymbol: .moonZzz)
        }
      }

      Divider()

      Button {
        monitorPreferences.clearSnooze(for: monitorType)
        monitorPreferences.setEnabled(false, for: monitorType)
      } label: {
        Label("Turn Off", systemSymbol: .bellSlash)
      }
    } label: {
      HStack(spacing: 4) {
        Text(statusLabel(for: monitorType))
        Image(systemSymbol: .chevronUpChevronDown)
      }
      .font(.subheadline)
    }
  }

  private func statusLabel(for monitorType: MonitorType) -> String {
    if monitorPreferences.isSnoozed(for: monitorType) {
      return "Snoozed"
    } else if monitorPreferences.isEnabled(for: monitorType) {
      return "On"
    } else {
      return "Off"
    }
  }

  // MARK: - Helpers

  private func monitorIcon(for monitorType: MonitorType) -> SFSymbol {
    switch monitorType {
    case .recovery:
      return .heartFill
    case .stress:
      return .flameFill
    case .sleep:
      return .moonFill
    }
  }

  private func monitorColor(for monitorType: MonitorType) -> Color {
    switch monitorType {
    case .recovery:
      return .red
    case .stress:
      return .orange
    case .sleep:
      return .indigo
    }
  }
}

#Preview {
  PreviewEnvironment {
    NotificationSettingsView()
  }
}
