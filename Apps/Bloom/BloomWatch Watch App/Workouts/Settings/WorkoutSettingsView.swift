//
//  WorkoutSettingsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct WorkoutSettingsView: View {
  @ObservedObject private var pinnedWorkoutsManager = PinnedWorkoutsManager.shared
  @State private var provider = HeartRateZoneSettingsProvider.shared
  @State private var presentedNavigationDestination: AnyView?

  var body: some View {
    NavigationStack {
      List {
        starredWorkoutsCell
        heartRateZonesCell

        #if DEBUG
        debugDataCell
        #endif
      }
      .listStyle(.carousel)
      .navigationTitle("Settings")
      .navigationDestination($presentedNavigationDestination)
    }
  }
}

// MARK: - Views

private extension WorkoutSettingsView {

  var starredWorkoutsCell: some View {
    HStack(spacing: 10) {
      WorkoutIcon(
        symbol: .starFill,
        scale: .small
      )

      VStack(alignment: .leading, spacing: 2) {
        Text("Starred Workouts")
          .font(.caption)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.white)

        Text("\(pinnedWorkoutsManager.pinnedWorkoutIds.count) workouts")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.vertical, 10)
    .selectable()
    .onTapGesture {
      presentedNavigationDestination = StarredWorkoutsSettingsView().asAny
    }
  }

  var heartRateZonesCell: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(Color.mutedPink.gradient)
        .overlay {
          Image(systemSymbol: .heartFill)
            .font(.system(size: 20))
            .foregroundStyle(.black)
        }
        .frame(square: 35)

      VStack(alignment: .leading, spacing: 2) {
        Text("HR Zones")
          .font(.caption)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.white)

        Text(provider.modeDisplayName)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.vertical, 10)
    .selectable()
    .onTapGesture {
      presentedNavigationDestination = HeartRateZoneSettingsView().asAny
    }
  }

  #if DEBUG
  var debugDataCell: some View {
    Section {
      HStack(spacing: 10) {
        Circle()
          .fill(.orange.gradient)
          .overlay {
            Image(systemSymbol: .ladybugFill)
              .font(.system(size: 20))
              .foregroundStyle(.black)
          }
          .frame(square: 35)

        Text("Debug Data")
          .font(.caption)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.white)

        Spacer()
      }
      .padding(.vertical, 10)
      .selectable()
      .onTapGesture {
        presentedNavigationDestination = DebugDataView().asAny
      }
    } header: {
      Text("Developer")
    }
  }
  #endif
}

#Preview {
  PreviewEnvironment {
    WorkoutSettingsView()
  }
}
