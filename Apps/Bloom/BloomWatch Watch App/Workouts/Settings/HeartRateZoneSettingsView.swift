//
//  HeartRateZoneSettingsView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-05.
//

import SwiftUI
import SFSafeSymbols
import BloomFoundation
import CoreHealth

struct HeartRateZoneSettingsView: View {
  @State private var provider = HeartRateZoneSettingsProvider.shared

  var body: some View {
    List {
      modeSection
      settingsSection
    }
    .navigationTitle("HR Zones")
  }
}

// MARK: - Mode Section

private extension HeartRateZoneSettingsView {

  var modeSection: some View {
    Picker("Mode", selection: Binding(
      get: { provider.mode },
      set: { provider.mode = $0 }
    )) {
      ForEach(HeartRateZoneMode.allCases, id: \.self) { mode in
        Text(mode.displayName).tag(mode)
      }
    }
  }
}

// MARK: - Settings Section

private extension HeartRateZoneSettingsView {

  @ViewBuilder
  var settingsSection: some View {
    switch provider.mode {
    case .automatic:
      automaticSection
    case .semiManual:
      semiManualSection
    case .manual:
      manualSection
    }
  }

  @ViewBuilder
  var automaticSection: some View {
    Section {
      heartRateCell(title: "Max HR", value: provider.maxHeartRate)
      heartRateCell(title: "Resting HR", value: provider.restingHeartRate)
    } header: {
      Text("Heart Rate")
    }

    Section {
      zoneCell(zone: 1, color: .heartRateZone1, value: provider.zone1Threshold)
      zoneCell(zone: 2, color: .heartRateZone2, value: provider.zone2Threshold)
      zoneCell(zone: 3, color: .heartRateZone3, value: provider.zone3Threshold)
      zoneCell(zone: 4, color: .heartRateZone4, value: provider.zone4Threshold)
      zoneCell(zone: 5, color: .heartRateZone5, value: provider.zone5Threshold)
    } header: {
      Text("Zones")
    }
  }

  @ViewBuilder
  var semiManualSection: some View {
    Section {
      NavigationLink {
        HeartRateValueEditView(
          title: "Max HR",
          value: Binding(
            get: { provider.maxHeartRate },
            set: { provider.maxHeartRate = $0 }
          ),
          range: 120...220
        )
      } label: {
        heartRateCell(title: "Max HR", value: provider.maxHeartRate, showDisclosure: true)
      }

      NavigationLink {
        HeartRateValueEditView(
          title: "Resting HR",
          value: Binding(
            get: { provider.restingHeartRate },
            set: { provider.restingHeartRate = $0 }
          ),
          range: 30...100
        )
      } label: {
        heartRateCell(title: "Resting HR", value: provider.restingHeartRate, showDisclosure: true)
      }
    } header: {
      Text("Custom Heart Rate")
    }

    Section {
      zoneCell(zone: 1, color: .heartRateZone1, value: provider.zone1Threshold)
      zoneCell(zone: 2, color: .heartRateZone2, value: provider.zone2Threshold)
      zoneCell(zone: 3, color: .heartRateZone3, value: provider.zone3Threshold)
      zoneCell(zone: 4, color: .heartRateZone4, value: provider.zone4Threshold)
      zoneCell(zone: 5, color: .heartRateZone5, value: provider.zone5Threshold)
    } header: {
      Text("Zones")
    }
  }

  @ViewBuilder
  var manualSection: some View {
    Section {
      NavigationLink {
        HeartRateValueEditView(
          title: "Zone 1",
          value: Binding(
            get: { provider.zone1Threshold },
            set: { provider.zone1Threshold = $0 }
          ),
          range: 60...220
        )
      } label: {
        zoneCell(zone: 1, color: .heartRateZone1, value: provider.zone1Threshold, showDisclosure: true)
      }

      NavigationLink {
        HeartRateValueEditView(
          title: "Zone 2",
          value: Binding(
            get: { provider.zone2Threshold },
            set: { provider.zone2Threshold = $0 }
          ),
          range: 60...220
        )
      } label: {
        zoneCell(zone: 2, color: .heartRateZone2, value: provider.zone2Threshold, showDisclosure: true)
      }

      NavigationLink {
        HeartRateValueEditView(
          title: "Zone 3",
          value: Binding(
            get: { provider.zone3Threshold },
            set: { provider.zone3Threshold = $0 }
          ),
          range: 60...220
        )
      } label: {
        zoneCell(zone: 3, color: .heartRateZone3, value: provider.zone3Threshold, showDisclosure: true)
      }

      NavigationLink {
        HeartRateValueEditView(
          title: "Zone 4",
          value: Binding(
            get: { provider.zone4Threshold },
            set: { provider.zone4Threshold = $0 }
          ),
          range: 60...220
        )
      } label: {
        zoneCell(zone: 4, color: .heartRateZone4, value: provider.zone4Threshold, showDisclosure: true)
      }

      NavigationLink {
        HeartRateValueEditView(
          title: "Zone 5",
          value: Binding(
            get: { provider.zone5Threshold },
            set: { provider.zone5Threshold = $0 }
          ),
          range: 60...220
        )
      } label: {
        zoneCell(zone: 5, color: .heartRateZone5, value: provider.zone5Threshold, showDisclosure: true)
      }

      NavigationLink {
        HeartRateValueEditView(
          title: "Max HR",
          value: Binding(
            get: { provider.maxHeartRate },
            set: { provider.maxHeartRate = $0 }
          ),
          range: 120...220
        )
      } label: {
        heartRateCell(title: "Max HR", value: provider.maxHeartRate, showDisclosure: true)
      }
    } header: {
      Text("Zone Thresholds")
    }
  }
}

// MARK: - Cell Components

private extension HeartRateZoneSettingsView {

  func heartRateCell(title: String, value: Double, showDisclosure: Bool = false) -> some View {
    HStack {
      Text(title)
        .font(.caption)
        .fontDesign(.rounded)

      Spacer()

      Text("\(Int(value)) bpm")
        .font(.caption)
        .foregroundStyle(.secondary)

      if showDisclosure {
        Image(systemSymbol: .chevronRight)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
  }

  func zoneCell(zone: Int, color: Color, value: Double, showDisclosure: Bool = false) -> some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 12, height: 12)

      Text("Zone \(zone)")
        .font(.caption)
        .fontDesign(.rounded)

      Spacer()

      Text("\(Int(value)) bpm")
        .font(.caption)
        .foregroundStyle(.secondary)

      if showDisclosure {
        Image(systemSymbol: .chevronRight)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    NavigationStack {
      HeartRateZoneSettingsView()
    }
  }
}
