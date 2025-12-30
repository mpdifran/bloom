//
//  YouSettingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-27.
//

import SwiftUI
import BloomUI
import CoreHealth
import DataContainer
import SFSafeSymbols

struct YouSettingsView: View {

  @State private var navigationPushView: AnyView?
  @YouSettingsStorage("YouView.settings") private var youSettings = YouSettings()

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        sectionOrderSection

        featureSection
      }
      .navigationTitle("Preferences")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination($navigationPushView)
      .presentationDragIndicator(.visible)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .onChange(of: aiFeatureSettings.biologicalAgeEnabled) { _, _ in
        Task {
          await ConsentManager.shared.syncGranularConsentSilently()
        }
      }
    }
  }
}

private extension YouSettingsView {

  var sectionOrderSection: some View {
    VStack(spacing: 0) {
      HStack {
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
      .padding(.horizontal)

      VStack(spacing: 0) {
        ForEach(Array(youSettings.sectionOrder.enumerated()), id: \.element) { index, section in
          if shouldShowSection(section) {
            SectionOrderRow(
              section: section,
              canMoveUp: index > 0,
              canMoveDown: index < youSettings.sectionOrder.count - 1,
              onMoveUp: {
                withAnimation {
                  youSettings.sectionOrder.swapAt(index, index - 1)
                }
              },
              onMoveDown: {
                withAnimation {
                  youSettings.sectionOrder.swapAt(index, index + 1)
                }
              }
            )

            if index < youSettings.sectionOrder.count - 1 && shouldShowSection(youSettings.sectionOrder[index + 1]) {
              Divider()
                .padding(.leading, 52)
            }
          }
        }
      }
      .cardContainer()
    }
  }

  var featureSection: some View {
    VStack {
      SectionTitleView("Biological Age")
        .padding(.horizontal)

      BiologicalAgePrivacyAIFeatureOptInCell(extraContext: "Bud will use the Personal Data Categories enabled below to calculate your biological age.")
        .cardContainer()

      AIDataShareCell()
        .cardContainer()
        .onTapGesture {
          navigationPushView = AIDataSharingView().asAny
        }
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
  let canMoveUp: Bool
  let canMoveDown: Bool
  let onMoveUp: () -> Void
  let onMoveDown: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: section.systemImage)
        .font(.body)
        .foregroundStyle(.tint)
        .frame(width: 24)

      Text(section.name)
        .font(.body)

      Spacer()

      HStack(spacing: 4) {
        Button {
          onMoveUp()
        } label: {
          Image(systemSymbol: .chevronUp)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(canMoveUp ? .primary : .tertiary)
        }
        .disabled(!canMoveUp)

        Button {
          onMoveDown()
        } label: {
          Image(systemSymbol: .chevronDown)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(canMoveDown ? .primary : .tertiary)
        }
        .disabled(!canMoveDown)
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 12)
    .padding(.horizontal)
    .contentShape(Rectangle())
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      YouSettingsView()
    }
  }
}
