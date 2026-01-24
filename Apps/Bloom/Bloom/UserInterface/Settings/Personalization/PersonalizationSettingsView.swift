//
//  PersonalizationSettingsView.swift
//  Bloom
//
//  Created by Claude on 2025-06-06.
//

import SwiftUI
import DataContainer
import BloomFoundation
import SFSafeSymbols
import CoreHealth
import HealthKit

struct PersonalizationSettingsView: View {
  @ObservedObject private var healthManager = HealthManager.shared

  @State private var presentedSheet: AnyView?

  @FocusState private var isFocused: Bool

  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      BloomScrollView {
        userDetailsSection
        lifestyleSection
        userFactsSection
      }
      .navigationTitle("Personal Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          DismissButton()
        }
      }
      .sheet($presentedSheet)
    }
    .shelf(isVisible: isFocused) {
      Button {
        isFocused = false
      } label: {
        Text("Done")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onChange(of: healthManager.smokingStatus) { _, _ in
      Task {
        await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()
      }
    }
    .onChange(of: healthManager.smokingQuitDate) { _, _ in
      Task {
        await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()
      }
    }
  }
}

private extension PersonalizationSettingsView {
  
  var userDetailsSection: some View {
    VStack {
      SectionTitleView("Personal Details")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Birth Month (Optional)") {
          Picker("", selection: $healthManager.birthMonth) {
            Text("Not Set").tag(0)
            ForEach(1...12, id: \.self) { month in
              Text(Calendar.current.monthSymbols[month - 1]).tag(month)
            }
          }
          .pickerStyle(.menu)
        }

        Divider()

        SettingsCell("Birth Year") {
          Picker("", selection: $healthManager.birthYear) {
            ForEach((1924...Calendar.current.component(.year, from: .now)).reversed(), id: \.self) { year in
              Text(String(year))
                .tag(year)
            }
          }
          .pickerStyle(.menu)
        }

        Divider()

        SettingsCell("Sex") {
          Picker("", selection: $healthManager.sexKind) {
            ForEach(HKBiologicalSex.allCases, id: \.self) { sex in
              Text(sex.name)
                .tag(sex)
            }
          }
          .pickerStyle(.menu)
        }

        Divider()

        SettingsCell("Height") {
          HeightEditorTextField()
            .focused($isFocused)
        }
        
        if healthManager.sex() == .female {
          Divider()
          
          SettingsCell("Breastfeeding") {
            Toggle("", isOn: healthManager.$isBreastfeeding)
              .tint(.mutedGreen)
          }

          Divider()

          SettingsCell("Pregnant") {
            Toggle("", isOn: healthManager.$isPregnant)
              .tint(.mutedGreen)
          }
        }
      }
    }
  }
  
  var lifestyleSection: some View {
    VStack {
      SectionTitleView("Lifestyle")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Smoking Status") {
          Picker("", selection: $healthManager.smokingStatus) {
            ForEach(SmokingStatus.allCases, id: \.self) { status in
              Text(status.displayName)
                .tag(status)
            }
          }
          .pickerStyle(.menu)
        }

        if healthManager.smokingStatus == .former {
          Divider()

          SettingsCell("Quit Date") {
            DatePicker(
              "",
              selection: Binding(
                get: { healthManager.smokingQuitDate ?? Date() },
                set: { healthManager.smokingQuitDate = $0 }
              ),
              in: ...Date(),
              displayedComponents: .date
            )
            .datePickerStyle(.compact)
          }
        }
      }
    }
  }

  var userFactsSection: some View {
    VStack {
      SectionTitleView("Bud")
        .padding(.horizontal)

      SettingsSectionContainer {
        NavigationLink {
          UserFactsView()
        } label: {
          SettingsCell("Bud's Memory", iconType: .disclosure) {
            EmptyView()
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    PersonalizationSettingsView()
  }
}
