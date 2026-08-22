//
//  TodaySettingsView.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import SwiftUI
import AppUI
import BloomUI
import SFSafeSymbols
import CoreHealth
@preconcurrency import EventKit

struct TodaySettingsView: View {
  @TodaySettingsStorage("TodayView.settings") private var todaySettings = TodaySettings()
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared
  @ObservedObject private var entitlementController = EntitlementController.shared

  @State private var selectedTimeMode: TimeMode = .morning
  @State private var editingTimeMode: TimeMode?
  @State private var presentedSheet: AnyView?
  @State private var draggedSection: TodaySection?
  @State private var navigationPushView: AnyView?

  var body: some View {
    NavigationStack {
      BloomScrollView {
        if entitlementController.hasBloomPro == true {
          aiInsightsSection
        }
        calendarSection
        timeConfigurationSection
        sectionsConfigurationSection
      }
      .tint(selectedTimeMode.tintColor)
      .navigationTitle("Preferences")
      .navigationBarTitleDisplayMode(.inline)
      .sensoryFeedback(.selection, trigger: selectedTimeMode)
      .navigationDestination($navigationPushView)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .onChange(of: aiFeatureSettings.todayInsightsEnabled) { _, _ in
        Task {
          await ConsentManager.shared.syncGranularConsentSilently()
        }
      }
    }
    .presentationDragIndicator(.visible)
    .sheet($presentedSheet)
    .onAppear {
      selectedTimeMode = TimeMode.current(for: .now, settings: todaySettings)
    }
    .task {
      await loadCalendarSettings()
    }
  }
}

private extension TodaySettingsView {

  func loadCalendarSettings() async {
    // CalendarPreferenceManager handles initialization automatically
  }

  var aiInsightsSection: some View {
    VStack {
      SectionTitleView("Today Insights")
        .padding(.horizontal)

      TodayInsightsPrivacyAIFeatureOptInCell(
        extraContext: String(
          localized: "Bud will use the Personal Data Categories enabled below.",
          comment: "Extra context under the Today Insights opt-in toggle"
        )
      )
        .cardContainer()

      AIDataShareCell()
        .cardContainer()
        .onTapGesture {
          navigationPushView = AIDataSharingView().asAny
        }
    }
  }

  var calendarSection: some View {
    VStack {
      SectionTitleView("Calendars")
        .padding(.horizontal)
      
      SettingsSectionContainer {
        SettingsCell("Show Calendars", iconType: .disclosure) {
          Text(calendarCountText)
        }
        .onTapGesture {
          navigationPushView = CalendarSelectionView().asAny
        }
      }
    }
  }
  
  var calendarCountText: String {
    let calendars = CalendarManager.shared.getAllCalendars()
    let selectedCount = CalendarPreferenceManager.shared.selectedCalendarIdentifiers.count
    
    if selectedCount == 0 {
      return String(localized: "None Selected", comment: "Calendar count when no calendars are selected")
    } else if selectedCount == calendars.count && calendars.count > 0 {
      return String(localized: "All Calendars", comment: "Calendar count when every calendar is selected")
    } else {
      return String(localized: "\(selectedCount) Selected", comment: "Calendar count, %lld is how many calendars are selected")
    }
  }

  var timeConfigurationSection: some View {
    VStack {
      SectionTitleView("Phases")
        .padding(.horizontal)

      SettingsSectionContainer {
        ForEach(Array(TimeMode.allCases.enumerated()), id: \.element.id) { index, mode in
          if index > 0 {
            Divider()
          }

          TimeConfigurationCell(
            timeMode: mode,
            startHour: todaySettings.startHour(for: mode),
            startMinute: todaySettings.startMinute(for: mode),
            todaySettings: todaySettings,
            onTimeChanged: { hour, minute in
              adjustTimeModesAfterChange(mode: mode, newHour: hour, newMinute: minute)
            }
          )
        }
      }
    }
  }

  var sectionsConfigurationSection: some View {
    VStack {
      HStack(alignment: .firstTextBaseline) {
        SectionTitleView("Sections")
        Spacer()
        Button("Reset") {
          resetCurrentModeToDefaults()
        }
        .font(.callout)
        .bold()
        .foregroundStyle(.tint)
      }
      .padding(.horizontal)

      timeModeSelector
      activeSectionsView
    }
  }

  var timeModeSelector: some View {
    HStack(spacing: 0) {
      ForEach(TimeMode.allCases) { mode in
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedTimeMode = mode
          }
        } label: {
          VStack(spacing: 6) {
            Image(systemSymbol: mode.icon)
              .font(.title2)
            Text(mode.displayName)
              .font(.caption)
              .fontDesign(.rounded)
              .bold()
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .foregroundStyle(selectedTimeMode == mode ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.secondary))
          .background(
            selectedTimeMode == mode ? AnyShapeStyle(.tint.tertiary) : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 10)
          )
        }
        .buttonStyle(.plain)
        .tint(mode.tintColor)
      }
    }
    .cardContainer()
  }

  var activeSectionsView: some View {
    VStack(spacing: 8) {
      let configuration = todaySettings.configuration(for: selectedTimeMode)

      ForEach(configuration.sectionOrder) { section in
        // Only show sections that match user's sex
        if !section.requiresFemale || HealthManager.shared.sex() == .female {
          TodayViewSectionCell(
            section: section,
            isEnabled: Binding(
              get: {
                // Show as disabled if requires Bloom Plus and user doesn't have it
                let hasBloomPlus = EntitlementController.shared.hasBloomPro == true
                if section.requiresBloomPlus && !hasBloomPlus {
                  return false
                }
                return configuration.enabledSections.contains(section)
              },
              set: { _ in toggleSection(section) }
            )
          )
          .scaleEffect(draggedSection == section ? 1.02 : 1.0)
          .onDrag {
            self.draggedSection = section
            return NSItemProvider(object: section.rawValue as NSString)
          }
          .onDrop(
            of: [.text],
            delegate: SectionDropDelegate(
              section: section,
              todaySettings: $todaySettings,
              selectedTimeMode: selectedTimeMode,
              draggedSection: $draggedSection
            )
          )
        }
      }
    }
    .animation(.easeInOut(duration: 0.2), value: draggedSection)
  }
}

private extension TodaySettingsView {

  func toggleSection(_ section: TodaySection) {
    // Don't allow toggling sections that require Bloom Plus if user doesn't have it
    let hasBloomPlus = EntitlementController.shared.hasBloomPro == true
    if section.requiresBloomPlus && !hasBloomPlus {
      return
    }

    // Don't allow toggling female-only sections if user is male
    if section.requiresFemale && HealthManager.shared.sex() != .female {
      return
    }

    withAnimation(.easeInOut(duration: 0.2)) {
      var configuration = todaySettings.configuration(for: selectedTimeMode)
      if configuration.enabledSections.contains(section) {
        configuration.enabledSections.remove(section)
      } else {
        configuration.enabledSections.insert(section)
      }
      todaySettings.setConfiguration(configuration, for: selectedTimeMode)
    }
  }
  
  func resetCurrentModeToDefaults() {
    withAnimation(.easeInOut(duration: 0.3)) {
      var defaultConfiguration = TodaySettings.TimeModeConfiguration(for: selectedTimeMode)

      // Remove sections that require Bloom Plus if user doesn't have it
      let hasBloomPlus = EntitlementController.shared.hasBloomPro == true
      if !hasBloomPlus {
        for section in defaultConfiguration.enabledSections {
          if section.requiresBloomPlus {
            defaultConfiguration.enabledSections.remove(section)
          }
        }
      }

      // Remove female-only sections if user is male
      if HealthManager.shared.sex() != .female {
        for section in defaultConfiguration.enabledSections {
          if section.requiresFemale {
            defaultConfiguration.enabledSections.remove(section)
          }
        }
      }

      todaySettings.setConfiguration(defaultConfiguration, for: selectedTimeMode)
    }
  }
  
  func adjustTimeModesAfterChange(mode: TimeMode, newHour: Int, newMinute: Int) {
    // Create a local copy to modify
    var settings = todaySettings

    // Set the new hour and minute for the changed mode
    settings.setStartHour(newHour, for: mode)
    settings.setStartMinute(newMinute, for: mode)

    // Ensure all time modes stay in order with at least 1 hour gap
    switch mode {
    case .morning:
      // If morning is changed, adjust afternoon, evening, and night if needed
      let minAfternoon = min(newHour + 1, 23)
      if settings.afternoonStartHour <= minAfternoon {
        settings.afternoonStartHour = min(minAfternoon + 1, 23)

        let minEvening = min(settings.afternoonStartHour + 1, 23)
        if settings.eveningStartHour <= minEvening {
          settings.eveningStartHour = min(minEvening + 1, 23)

          let minNight = min(settings.eveningStartHour + 1, 23)
          if settings.nightStartHour <= minNight {
            settings.nightStartHour = min(minNight + 1, 23)
          }
        }
      }

    case .afternoon:
      // Adjust morning if it's too close/after
      if settings.morningStartHour >= newHour {
        settings.morningStartHour = max(newHour - 1, 0)
      }

      // Adjust evening and night if needed
      let minEvening = min(newHour + 1, 23)
      if settings.eveningStartHour <= minEvening {
        settings.eveningStartHour = min(minEvening + 1, 23)

        let minNight = min(settings.eveningStartHour + 1, 23)
        if settings.nightStartHour <= minNight {
          settings.nightStartHour = min(minNight + 1, 23)
        }
      }

    case .evening:
      // Adjust earlier modes if needed
      if settings.afternoonStartHour >= newHour {
        settings.afternoonStartHour = max(newHour - 1, 0)

        if settings.morningStartHour >= settings.afternoonStartHour {
          settings.morningStartHour = max(settings.afternoonStartHour - 1, 0)
        }
      }

      // Adjust night if needed
      let minNight = min(newHour + 1, 23)
      if settings.nightStartHour <= minNight {
        settings.nightStartHour = min(minNight + 1, 23)
      }

    case .night:
      // Adjust earlier modes if needed
      if settings.eveningStartHour >= newHour {
        settings.eveningStartHour = max(newHour - 1, 0)

        if settings.afternoonStartHour >= settings.eveningStartHour {
          settings.afternoonStartHour = max(settings.eveningStartHour - 1, 0)

          if settings.morningStartHour >= settings.afternoonStartHour {
            settings.morningStartHour = max(settings.afternoonStartHour - 1, 0)
          }
        }
      }
    @unknown default:
      break
    }

    // Assign the modified copy back to trigger persistence
    todaySettings = settings
  }
}

private struct SectionDropDelegate: DropDelegate {
  let section: TodaySection
  @Binding var todaySettings: TodaySettings
  let selectedTimeMode: TimeMode
  @Binding var draggedSection: TodaySection?
  
  func dropEntered(info: DropInfo) {
    guard let draggedSection = draggedSection else { return }
    
    if draggedSection != section {
      var configuration = todaySettings.configuration(for: selectedTimeMode)
      let from = configuration.sectionOrder.firstIndex(of: draggedSection)!
      let to = configuration.sectionOrder.firstIndex(of: section)!
      
      withAnimation(.default) {
        configuration.sectionOrder.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        todaySettings.setConfiguration(configuration, for: selectedTimeMode)
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
    TodaySettingsView()
  }
}
