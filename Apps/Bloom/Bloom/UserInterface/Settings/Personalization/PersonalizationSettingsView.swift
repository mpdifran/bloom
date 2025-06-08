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

struct PersonalizationSettingsView: View {
  @ObservedObject private var healthManager = HealthManager.shared
  @State private var presentedSheet: AnyView?
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      BloomScrollView {
        userDetailsSection
        userFactsSection
      }
      .navigationTitle("Personal Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .sheet($presentedSheet)
    }
  }
}

private extension PersonalizationSettingsView {
  
  var userDetailsSection: some View {
    VStack {
      SectionTitleView("Personal Details")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Birthday") {
          DatePicker(
            "",
            selection: $healthManager.birthday,
            in: ...Date(),
            displayedComponents: .date
          )
        }

        Divider()

        SettingsCell("Sex") {
          Picker("", selection: $healthManager.isFemale) {
            Text("Male")
              .tag(false)
            Text("Female")
              .tag(true)
          }
          .pickerStyle(.segmented)
          .frame(width: 150, height: 50)
        }

        Divider()

        SettingsCell("Height") {
          HeightEditorTextField()
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
  
  var userFactsSection: some View {
    VStack {
      SectionTitleView("Bud")
        .padding(.horizontal)

      SettingsSectionContainer {
        NavigationLink {
          UserFactsView()
        } label: {
          SettingsCell("Bud Memory", showDisclosureIndicator: true) {
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
