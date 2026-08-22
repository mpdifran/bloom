//
//  HeartRateZoneSettingsView.swift
//  Bloom
//
//  Created by Claude on 2026-02-04.
//

import SwiftUI
import CoreHealth
import AppUI

struct HeartRateZoneSettingsView: View {
  @ObservedObject private var healthManager = HealthManager.shared
  @State private var calculatedZones: HeartRateZones?
  @State private var isLoading = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    BloomScrollView {
      modePickerSection

      switch healthManager.heartRateZoneMode {
      case .automatic:
        automaticModeSection
      case .semiManual:
        semiManualModeSection
      case .manual:
        manualModeSection
      @unknown default:
        EmptyView()
      }

      zonePreviewSection

      if healthManager.heartRateZoneMode != .manual {
        HealthCitationLinkView(
          url: .mayoClinicHeartRateZones,
          title: "Zone calculations based on the Karvonen Formula."
        )
        .padding(.horizontal)
      }
    }
    .navigationTitle("Heart Rate Zones")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadZones()
    }
    .onChange(of: healthManager.heartRateZoneMode) { _, _ in
      Task { await loadZones() }
    }
    .onChange(of: healthManager.manualMaxHeartRate) { _, _ in
      Task { await loadZones() }
    }
    .onChange(of: healthManager.manualRestingHeartRate) { _, _ in
      Task { await loadZones() }
    }
    .sensoryFeedback(.impact, trigger: healthManager.heartRateZoneMode)
  }
}

// MARK: - Views

private extension HeartRateZoneSettingsView {

  var modePickerSection: some View {
    VStack {
      SectionTitleView("Calculation Mode")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Mode") {
          Picker("", selection: $healthManager.heartRateZoneMode) {
            ForEach(HeartRateZoneCalculationMode.allCases, id: \.self) { mode in
              Text(mode.displayName).tag(mode)
            }
          }
          .pickerStyle(.menu)
        }
      }

      Text(healthManager.heartRateZoneMode.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
        .padding(.horizontal)
    }
  }

  var automaticModeSection: some View {
    VStack {
      SectionTitleView("Calculated Values")
        .padding(.horizontal)

      SettingsSectionContainer {
        if let zones = calculatedZones {
          SettingsCell("Max Heart Rate") {
            Text("\(zones.maxHeartRate.format()) bpm")
              .foregroundStyle(.secondary)
          }

          Divider()

          SettingsCell("Resting Heart Rate") {
            Text("\(zones.restingHeartRate.format()) bpm")
              .foregroundStyle(.secondary)
          }

          Divider()

          SettingsCell("Heart Rate Reserve") {
            Text("\(zones.heartRateReserve.format()) bpm")
              .foregroundStyle(.secondary)
          }
        } else if isLoading {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .padding(.vertical)
        } else {
          ContentUnavailableView(
            "No Data Available",
            systemSymbol: .heartSlashFill,
            description: Text("Wear your Apple Watch to record resting heart rate data.")
          )
          .fixedSize(horizontal: false, vertical: true)
          .padding(.vertical)
          .horizontallyCentered()
        }
      }
    }
  }

  var semiManualModeSection: some View {
    VStack {
      SectionTitleView("Custom Heart Rate")
        .padding(.horizontal)

      SettingsSectionContainer {
        heartRateInputRow(
          title: "Max Heart Rate",
          value: $healthManager.manualMaxHeartRate,
          placeholder: "185"
        )

        Divider()

        heartRateInputRow(
          title: "Resting Heart Rate",
          value: $healthManager.manualRestingHeartRate,
          placeholder: "60"
        )
      }
    }
  }

  var manualModeSection: some View {
    VStack {
      SectionTitleView("Custom Zone Thresholds")
        .padding(.horizontal)

      SettingsSectionContainer {
        heartRateInputRow(
          title: "Zone 1 Starts At",
          value: $healthManager.manualZone1Threshold,
          placeholder: "110",
          color: .heartRateZone1
        )

        Divider()

        heartRateInputRow(
          title: "Zone 2 Starts At",
          value: $healthManager.manualZone2Threshold,
          placeholder: "125",
          color: .heartRateZone2
        )

        Divider()

        heartRateInputRow(
          title: "Zone 3 Starts At",
          value: $healthManager.manualZone3Threshold,
          placeholder: "140",
          color: .heartRateZone3
        )

        Divider()

        heartRateInputRow(
          title: "Zone 4 Starts At",
          value: $healthManager.manualZone4Threshold,
          placeholder: "155",
          color: .heartRateZone4
        )

        Divider()

        heartRateInputRow(
          title: "Zone 5 Starts At",
          value: $healthManager.manualZone5Threshold,
          placeholder: "170",
          color: .heartRateZone5
        )

        Divider()

        heartRateInputRow(
          title: "Max Heart Rate",
          value: $healthManager.manualMaxHeartRate,
          placeholder: "185"
        )
      }
    }
    .onChange(of: healthManager.manualZone1Threshold) { _, _ in
      healthManager.saveManualZoneThresholds()
      Task { await loadZones() }
    }
    .onChange(of: healthManager.manualZone2Threshold) { _, _ in
      healthManager.saveManualZoneThresholds()
      Task { await loadZones() }
    }
    .onChange(of: healthManager.manualZone3Threshold) { _, _ in
      healthManager.saveManualZoneThresholds()
      Task { await loadZones() }
    }
    .onChange(of: healthManager.manualZone4Threshold) { _, _ in
      healthManager.saveManualZoneThresholds()
      Task { await loadZones() }
    }
    .onChange(of: healthManager.manualZone5Threshold) { _, _ in
      healthManager.saveManualZoneThresholds()
      Task { await loadZones() }
    }
  }

  /// `title` is a LocalizedStringKey, not a String: a String literal is passed straight to Text
  /// without a catalog lookup, so every row title rendered in English regardless of language.
  func heartRateInputRow(
    title: LocalizedStringKey,
    value: Binding<Double>,
    placeholder: String,
    color: Color? = nil
  ) -> some View {
    HStack {
      if let color {
        Circle()
          .fill(color)
          .frame(width: 12, height: 12)
      }

      Text(title)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      TextField(placeholder, value: value, format: .number)
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 60)

      Text("bpm")
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 12)
  }

  @ViewBuilder
  var zonePreviewSection: some View {
    if let zones = calculatedZones {
      VStack {
        SectionTitleView("Zone Preview")
          .padding(.horizontal)

        VStack(spacing: 0) {
          zonePreviewRow("Zone 1", range: zones.zone1RangeString, color: .heartRateZone1)
          Divider()
          zonePreviewRow("Zone 2", range: zones.zone2RangeString, color: .heartRateZone2)
          Divider()
          zonePreviewRow("Zone 3", range: zones.zone3RangeString, color: .heartRateZone3)
          Divider()
          zonePreviewRow("Zone 4", range: zones.zone4RangeString, color: .heartRateZone4)
          Divider()
          zonePreviewRow("Zone 5", range: zones.zone5RangeString, color: .heartRateZone5)
        }
        .padding(.horizontal)
        .cardContainer(includePadding: false)
      }
    }
  }

  /// `title` is a LocalizedStringKey for the same reason as `heartRateInputRow(title:…)`.
  /// `range` stays a String: it holds a runtime-formatted heart rate range.
  func zonePreviewRow(_ title: LocalizedStringKey, range: String, color: Color) -> some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 12, height: 12)

      Text(title)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      Text(range)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 12)
  }
}

// MARK: - Data Loading

private extension HeartRateZoneSettingsView {

  func loadZones() async {
    isLoading = true
    calculatedZones = await HealthStoreFetcher.shared.heartRateZones()
    isLoading = false
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    HeartRateZoneSettingsView()
  }
}
