//
//  MonitorSettingsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols

/// Settings view for Monitor tab preferences, following the You/Today pattern.
/// Opened as a sheet from the MonitorView toolbar.
struct MonitorSettingsView: View {

  @ObservedObject private var preferences = MonitorNotificationPreferences.shared

  @State private var showingSnoozeOptions: MonitorType?

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        notificationSection
      }
      .navigationTitle("Preferences")
      .navigationBarTitleDisplayMode(.inline)
      .presentationDragIndicator(.visible)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .confirmationDialog(
      "Snooze Notifications",
      isPresented: Binding(
        get: { showingSnoozeOptions != nil },
        set: { if !$0 { showingSnoozeOptions = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let monitorType = showingSnoozeOptions {
        ForEach(MonitorNotificationPreferences.SnoozeDuration.allCases, id: \.self) { duration in
          Button(duration.displayName) {
            preferences.snooze(monitorType, for: duration.timeInterval)
            showingSnoozeOptions = nil
          }
        }
        Button("Cancel", role: .cancel) {
          showingSnoozeOptions = nil
        }
      }
    }
  }

  // MARK: - Notification Section

  private var notificationSection: some View {
    VStack {
      SectionTitleView("Notifications")
        .padding(.horizontal)

      VStack(spacing: 0) {
        ForEach(Array(MonitorType.allCases.enumerated()), id: \.element) { index, monitorType in
          if index > 0 {
            Divider()
              .padding(.leading, 56)
          }
          monitorNotificationRow(for: monitorType)
        }
      }
      .cardContainer()

      Text("Get notified when a monitor needs your attention. Notifications are only sent when there's a change in your health status.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.top, 4)
    }
  }

  private func monitorNotificationRow(for monitorType: MonitorType) -> some View {
    HStack(spacing: 12) {
      Image(systemSymbol: monitorIcon(for: monitorType))
        .font(.title3)
        .foregroundStyle(monitorColor(for: monitorType))
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(monitorType.displayName)
          .font(.body)
          .fontWeight(.medium)

        if preferences.isSnoozed(for: monitorType) {
          if let snoozedUntil = preferences.snoozedUntil(for: monitorType) {
            Text("Snoozed until \(snoozedUntil, style: .date)")
              .font(.caption)
              .foregroundStyle(.orange)
          }
        } else if !preferences.isEnabled(for: monitorType) {
          Text("Notifications off")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if preferences.isSnoozed(for: monitorType) {
        Button("Unsnooze") {
          preferences.clearSnooze(for: monitorType)
        }
        .font(.caption)
        .foregroundStyle(.orange)
        .buttonStyle(.plain)
      } else {
        Menu {
          Button {
            preferences.setEnabled(!preferences.isEnabled(for: monitorType), for: monitorType)
          } label: {
            if preferences.isEnabled(for: monitorType) {
              Label("Turn Off", systemSymbol: .bellSlash)
            } else {
              Label("Turn On", systemSymbol: .bell)
            }
          }

          if preferences.isEnabled(for: monitorType) {
            Divider()
            Button {
              showingSnoozeOptions = monitorType
            } label: {
              Label("Snooze...", systemSymbol: .moonZzz)
            }
          }
        } label: {
          Toggle("", isOn: Binding(
            get: { preferences.isEnabled(for: monitorType) },
            set: { preferences.setEnabled($0, for: monitorType) }
          ))
          .labelsHidden()
        }
        .menuStyle(.borderlessButton)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
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
