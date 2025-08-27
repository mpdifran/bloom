//
//  TodaySettings.swift
//  Bloom
//
//  Created by Assistant on 2025-08-27.
//

import Foundation

struct TodaySettings: Codable {
  struct TimeModeConfiguration: Codable {
    var enabledSections: Set<TodaySection>
    var sectionOrder: [TodaySection]
    
    init(for timeMode: TimeMode) {
      switch timeMode {
      case .morning:
        self.sectionOrder = [
          .todaysAdvice,
          .insights,
          .sleepDetails,
          .reminders,
          .goals,
          .todaysEvents,
          .todaysWeather
        ]
        self.enabledSections = Set(self.sectionOrder)
        // Add remaining sections that are not enabled by default
        self.sectionOrder.append(contentsOf: [.tonightsSleep, .tomorrowsEvents, .tomorrowsWeather])
        
      case .afternoon:
        self.sectionOrder = [
          .todaysAdvice,
          .reminders,
          .goals,
          .todaysEvents,
          .todaysWeather
        ]
        self.enabledSections = Set(self.sectionOrder)
        // Add remaining sections that are not enabled by default
        self.sectionOrder.append(contentsOf: [.insights, .sleepDetails, .tonightsSleep, .tomorrowsEvents, .tomorrowsWeather])
        
      case .evening:
        self.sectionOrder = [
          .tonightsSleep,
          .reminders,
          .goals,
          .tomorrowsEvents,
          .tomorrowsWeather
        ]
        self.enabledSections = Set(self.sectionOrder)
        // Add remaining sections that are not enabled by default
        self.sectionOrder.append(contentsOf: [.todaysAdvice, .insights, .sleepDetails, .todaysEvents, .todaysWeather])

      case .night:
        self.sectionOrder = [
          .tonightsSleep,
          .tomorrowsEvents,
          .tomorrowsWeather
        ]
        self.enabledSections = Set(self.sectionOrder)
        // Add remaining sections that are not enabled by default
        self.sectionOrder.append(contentsOf: [.todaysAdvice, .insights, .sleepDetails, .reminders, .goals, .todaysEvents, .todaysWeather])
      }
    }
    
    init(enabledSections: Set<TodaySection>, sectionOrder: [TodaySection]) {
      self.enabledSections = enabledSections
      self.sectionOrder = sectionOrder
    }
  }
  
  var morningStartHour: Int
  var afternoonStartHour: Int
  var eveningStartHour: Int
  var nightStartHour: Int
  
  var morningConfiguration: TimeModeConfiguration
  var afternoonConfiguration: TimeModeConfiguration
  var eveningConfiguration: TimeModeConfiguration
  var nightConfiguration: TimeModeConfiguration
  
  init() {
    self.morningStartHour = TimeMode.morning.defaultStartHour
    self.afternoonStartHour = TimeMode.afternoon.defaultStartHour
    self.eveningStartHour = TimeMode.evening.defaultStartHour
    self.nightStartHour = TimeMode.night.defaultStartHour
    
    self.morningConfiguration = TimeModeConfiguration(for: .morning)
    self.afternoonConfiguration = TimeModeConfiguration(for: .afternoon)
    self.eveningConfiguration = TimeModeConfiguration(for: .evening)
    self.nightConfiguration = TimeModeConfiguration(for: .night)
  }
  
  func configuration(for timeMode: TimeMode) -> TimeModeConfiguration {
    let config = switch timeMode {
    case .morning:
      morningConfiguration
    case .afternoon:
      afternoonConfiguration
    case .evening:
      eveningConfiguration
    case .night:
      nightConfiguration
    }
    
    return migrateConfiguration(config, for: timeMode)
  }
  
  private func migrateConfiguration(_ config: TimeModeConfiguration, for timeMode: TimeMode) -> TimeModeConfiguration {
    let allCurrentSections = Set(TodaySection.allCases)
    let configSections = Set(config.sectionOrder)
    let missingSections = allCurrentSections.subtracting(configSections)
    
    // If no new sections, return as-is
    guard !missingSections.isEmpty else { return config }
    
    var newConfig = config
    
    // Add missing sections to the end of the order (disabled by default)
    newConfig.sectionOrder.append(contentsOf: missingSections.sorted { $0.defaultOrder < $1.defaultOrder })
    
    // For specific sections that should be enabled by default in certain modes,
    // we can add them to the enabled set
    for section in missingSections {
      if shouldBeEnabledByDefault(section: section, in: timeMode) {
        newConfig.enabledSections.insert(section)
        
        // Move it to the appropriate position in the order
        if let index = getInsertionIndex(for: section, in: timeMode, currentOrder: newConfig.sectionOrder) {
          // Remove from end and insert at correct position
          if let currentIndex = newConfig.sectionOrder.firstIndex(of: section) {
            newConfig.sectionOrder.remove(at: currentIndex)
            newConfig.sectionOrder.insert(section, at: index)
          }
        }
      }
    }
    
    return newConfig
  }
  
  private func shouldBeEnabledByDefault(section: TodaySection, in timeMode: TimeMode) -> Bool {
    // Check if this section should be enabled by default in this time mode
    let defaultConfig = TimeModeConfiguration(for: timeMode)
    return defaultConfig.enabledSections.contains(section)
  }
  
  private func getInsertionIndex(for section: TodaySection, in timeMode: TimeMode, currentOrder: [TodaySection]) -> Int? {
    // Get the default position for this section in this time mode
    let defaultConfig = TimeModeConfiguration(for: timeMode)
    guard let defaultIndex = defaultConfig.sectionOrder.firstIndex(of: section) else { return nil }
    
    // Find the best insertion point in the current order
    // Look for the section that should come after this one in the default order
    for i in (defaultIndex + 1)..<defaultConfig.sectionOrder.count {
      let nextSection = defaultConfig.sectionOrder[i]
      if let existingIndex = currentOrder.firstIndex(of: nextSection) {
        return existingIndex
      }
    }
    
    // If no section found after it, find the last enabled section and insert after it
    let enabledSections = defaultConfig.enabledSections
    for i in stride(from: currentOrder.count - 1, through: 0, by: -1) {
      if enabledSections.contains(currentOrder[i]) {
        return i + 1
      }
    }
    
    return 0 // Insert at beginning if no enabled sections found
  }
  
  mutating func setConfiguration(_ configuration: TimeModeConfiguration, for timeMode: TimeMode) {
    switch timeMode {
    case .morning:
      morningConfiguration = configuration
    case .afternoon:
      afternoonConfiguration = configuration
    case .evening:
      eveningConfiguration = configuration
    case .night:
      nightConfiguration = configuration
    }
  }
  
  func startHour(for timeMode: TimeMode) -> Int {
    switch timeMode {
    case .morning:
      return morningStartHour
    case .afternoon:
      return afternoonStartHour
    case .evening:
      return eveningStartHour
    case .night:
      return nightStartHour
    }
  }
  
  mutating func setStartHour(_ hour: Int, for timeMode: TimeMode) {
    switch timeMode {
    case .morning:
      morningStartHour = hour
    case .afternoon:
      afternoonStartHour = hour
    case .evening:
      eveningStartHour = hour
    case .night:
      nightStartHour = hour
    }
  }
}

