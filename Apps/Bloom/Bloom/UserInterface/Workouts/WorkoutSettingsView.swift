//
//  WorkoutSettingsView.swift
//  Bloom
//
//  Created by Claude on 2026-02-04.
//

import SwiftUI
import AppUI
import SFSafeSymbols
import CoreHealth

struct WorkoutSettingsView: View {
  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView {
        NavigationLink {
          WorkoutEquipmentView()
        } label: {
          equipmentCell
        }
        .buttonStyle(.plain)

        NavigationLink {
          HeartRateZoneSettingsView()
        } label: {
          heartRateZonesCell
        }
        .buttonStyle(.plain)
      }
      .navigationTitle("Workout Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
  }
}

// MARK: - Cells

private extension WorkoutSettingsView {

  var equipmentCell: some View {
    HStack {
      Image(systemSymbol: .dumbbellFill)
        .font(.title2)
        .foregroundStyle(.tint)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text("Workout Equipment")
          .font(.headline)
          .foregroundStyle(.primary)

        Text(equipmentSubtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
  }

  var heartRateZonesCell: some View {
    HStack {
      Image(systemSymbol: .heartFill)
        .font(.title2)
        .foregroundStyle(.heartRateZone4)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text("Heart Rate Zones")
          .font(.headline)
          .foregroundStyle(.primary)

        Text(heartRateZonesSubtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
  }

  var equipmentSubtitle: String {
    let count = healthManager.selectedWorkoutEquipment.count
    if count == 0 {
      return "No equipment selected"
    } else if count == 1 {
      return "1 item selected"
    } else {
      return "\(count) items selected"
    }
  }

  var heartRateZonesSubtitle: String {
    switch healthManager.heartRateZoneMode {
    case .automatic:
      return "Automatic"
    case .semiManual:
      return "Custom heart rate"
    case .manual:
      return "Custom zones"
    @unknown default:
      return "Automatic"
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    WorkoutSettingsView()
  }
}
