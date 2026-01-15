//
//  YouSettingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-27.
//

import SwiftUI
import CoreHealth
import DataContainer
import SFSafeSymbols

struct YouSettingsView: View {

  @State private var draggedSection: VitalModel.Kind?
  @YouSettingsStorage("YouView.settings") private var youSettings = YouSettings()
  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        personalDetailsSection
        sectionOrderSection
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
  }
}

private extension YouSettingsView {

  var personalDetailsSection: some View {
    VStack(spacing: 0) {
      SectionTitleView("Personal Details")
        .padding()

      VStack {
        LabeledContent("Birth Month (Optional)") {
          Picker("", selection: $healthManager.birthMonth) {
            Text("Not Set").tag(0)
            ForEach(1...12, id: \.self) { month in
              Text(Calendar.current.monthSymbols[month - 1]).tag(month)
            }
          }
          .pickerStyle(.menu)
        }
        .frame(height: 40)

        Divider()

        LabeledContent("Birth Year") {
          Picker("", selection: $healthManager.birthYear) {
            ForEach((1924...Calendar.current.component(.year, from: .now)).reversed(), id: \.self) { year in
              Text(String(year)).tag(year)
            }
          }
          .pickerStyle(.menu)
        }
        .frame(height: 40)
      }
      .cardContainer()
    }
    .onChange(of: healthManager.birthMonth) { _, _ in
      Task {
        await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()
      }
    }
    .onChange(of: healthManager.birthYear) { _, _ in
      Task {
        await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()
      }
    }
  }

  var sectionOrderSection: some View {
    VStack(spacing: 0) {
      HStack(alignment: .bottom) {
        SectionTitleView("Section Order")

        Spacer()

        Button {
          withAnimation {
            youSettings.sectionOrder = YouSettings.defaultOrder
          }
        } label: {
          Text("Reset")
            .font(.callout)
            .fontWeight(.semibold)
        }
      }
      .padding()

      VStack(spacing: 8) {
        ForEach(youSettings.sectionOrder, id: \.self) { section in
          if shouldShowSection(section) {
            SectionOrderRow(section: section)
              .scaleEffect(draggedSection == section ? 1.02 : 1.0)
              .onDrag {
                self.draggedSection = section
                return NSItemProvider(object: section.rawValue as NSString)
              }
              .onDrop(
                of: [.text],
                delegate: SectionDropDelegate(
                  section: section,
                  youSettings: $youSettings,
                  draggedSection: $draggedSection
                )
              )
          }
        }
      }
      .animation(.easeInOut(duration: 0.2), value: draggedSection)
    }
  }

  func shouldShowSection(_ section: VitalModel.Kind) -> Bool {
    switch section {
    case .cardioFitness:
      return false
    case .cycleTracking:
      return HealthManager.shared.sex() == .female
    default:
      return true
    }
  }
}

// MARK: - Section Order Row

private struct SectionOrderRow: View {
  let section: VitalModel.Kind

  var body: some View {
    HStack {
      Image(systemSymbol: .line3Horizontal)
        .font(.caption)
        .foregroundStyle(.tertiary)

      Image(systemName: section.systemImage)
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(width: 24)

      Text(section.name)
        .bold()
        .fontDesign(.rounded)

      Spacer()
    }
    .cardContainer()
  }
}

// MARK: - Section Drop Delegate

private struct SectionDropDelegate: DropDelegate {
  let section: VitalModel.Kind
  @Binding var youSettings: YouSettings
  @Binding var draggedSection: VitalModel.Kind?

  func dropEntered(info: DropInfo) {
    guard let draggedSection = draggedSection else { return }

    if draggedSection != section {
      let from = youSettings.sectionOrder.firstIndex(of: draggedSection)!
      let to = youSettings.sectionOrder.firstIndex(of: section)!

      withAnimation(.default) {
        youSettings.sectionOrder.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
      }
    }
  }

  func performDrop(info: DropInfo) -> Bool {
    draggedSection = nil
    return true
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      YouSettingsView()
    }
  }
}
