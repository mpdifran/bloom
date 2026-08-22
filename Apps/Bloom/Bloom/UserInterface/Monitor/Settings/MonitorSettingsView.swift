//
//  MonitorSettingsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import AppUI
import BloomUI
import SFSafeSymbols

/// Settings view for Monitor tab preferences, following the You/Today pattern.
/// Opened as a sheet from the MonitorView toolbar.
struct MonitorSettingsView: View {

  @ObservedObject private var preferences = MonitorNotificationPreferences.shared
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      BloomScrollView {
        healthPermissionSection
        notificationSection
        badgeSection
      }
      .navigationTitle("Preferences")
      .navigationBarTitleDisplayMode(.inline)
      .presentationDragIndicator(.visible)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .onChange(of: aiFeatureSettings.monitorEnabled) {
        Task {
          await ConsentManager.shared.syncGranularConsentSilently()
        }
      }
      .sheet($presentedSheet)
    }
  }

  // MARK: - Health Permission Section

  private var healthPermissionSection: some View {
    VStack {
      SectionTitleView("Health Data Sharing")
        .padding(.horizontal)

      MonitorPrivacyAIFeatureOptInCell()
        .cardContainer()

      AIDataShareCell()
        .cardContainer()
        .onTapGesture {
          presentedSheet = AIDataSharingView(showDismiss: true).asAny
        }

      Text("When enabled, Bud provides insights into your monitor results using the Personal Data categories above.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .horizontalAlignment(.leading)
        .padding(.horizontal)
        .padding(.top, 4)
    }
    .padding(.bottom, 16)
  }

  // MARK: - Notification Section

  private var notificationSection: some View {
    VStack {
      SectionTitleView("Notifications")
        .padding(.horizontal)

      VStack(spacing: 8) {
        ForEach(MonitorType.allCases, id: \.self) { monitorType in
          monitorRow(for: monitorType)
            .cardContainer()
        }
      }

      Text("Get notified when a monitor needs your attention. Notifications are only sent when a monitor changes to attention or alert.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
        .padding(.horizontal)
        .padding(.top, 4)
    }
  }

  // MARK: - Badge Section

  private var badgeSection: some View {
    VStack {
      SectionTitleView("Badges")
        .padding(.horizontal)

      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Show Badge")
            .font(.body)
            .fontWeight(.medium)

          Text("Display count on tab and app icon")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Toggle("", isOn: $preferences.badgesEnabled)
          .labelsHidden()
      }
      .cardContainer()
      .onChange(of: preferences.badgesEnabled) {
        MonitorViewModel.shared.updateBadges()
      }
    }
    .padding(.top, 16)
  }

  // MARK: - Monitor Row

  private func monitorRow(for monitorType: MonitorType) -> some View {
    let isActive = preferences.isEnabled(for: monitorType) || preferences.isSnoozed(for: monitorType)

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
    if preferences.isSnoozed(for: monitorType),
       let snoozedUntil = preferences.snoozedUntil(for: monitorType) {
      Text(daysRemainingText(until: snoozedUntil))
        .font(.caption)
        .foregroundStyle(.orange)
    } else if !preferences.isEnabled(for: monitorType) {
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
      return String(localized: "Less than 1 day remaining", comment: "Snooze subtitle when the snooze ends within a day")
    }

    return String(localized: "\(days) days remaining", comment: "Snooze subtitle showing how many whole days a monitor stays snoozed")
  }

  private func statusMenu(for monitorType: MonitorType) -> some View {
    Menu {
      Button {
        preferences.clearSnooze(for: monitorType)
        preferences.setEnabled(true, for: monitorType)
      } label: {
        Label("Turn On", systemSymbol: .bell)
      }

      Divider()

      ForEach(MonitorNotificationPreferences.SnoozeDuration.allCases, id: \.self) { duration in
        Button {
          preferences.snooze(monitorType, for: duration.timeInterval)
        } label: {
          Label("Snooze for \(duration.displayName)", systemSymbol: .moonZzz)
        }
      }

      Divider()

      Button {
        preferences.clearSnooze(for: monitorType)
        preferences.setEnabled(false, for: monitorType)
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
    if preferences.isSnoozed(for: monitorType) {
      return String(localized: "Snoozed", comment: "Monitor notification status shown in the settings menu button")
    } else if preferences.isEnabled(for: monitorType) {
      return String(localized: "On", comment: "Monitor notification status shown in the settings menu button")
    } else {
      return String(localized: "Off", comment: "Monitor notification status shown in the settings menu button")
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

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    MonitorSettingsView()
  }
}
