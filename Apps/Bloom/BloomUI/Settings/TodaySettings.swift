//
//  TodaySettings.swift
//  BloomUI
//
//  Created by Assistant on 2025-08-27.
//

import Foundation

public struct TodaySettings: Codable, TimeModeSettings {
  public struct TimeModeConfiguration: Codable {
    public var enabledSections: Set<TodaySection>
    public var sectionOrder: [TodaySection]

    public init(for timeMode: TimeMode) {
      switch timeMode {
      case .morning:
        self.sectionOrder = [
          .todaysAdvice,
          .insights,
          .sleepDetails,
          .phaseTip,
          .periodForecast,
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
          .phaseTip,
          .periodForecast,
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
          .phaseTip,
          .periodForecast,
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
          .phaseTip,
          .periodForecast,
          .tomorrowsEvents,
          .tomorrowsWeather
        ]
        self.enabledSections = Set(self.sectionOrder)
        // Add remaining sections that are not enabled by default
        self.sectionOrder.append(contentsOf: [.todaysAdvice, .insights, .sleepDetails, .reminders, .goals, .todaysEvents, .todaysWeather])
      }
    }

    public init(enabledSections: Set<TodaySection>, sectionOrder: [TodaySection]) {
      self.enabledSections = enabledSections
      self.sectionOrder = sectionOrder
    }
  }

  public var morningStartHour: Int
  public var afternoonStartHour: Int
  public var eveningStartHour: Int
  public var nightStartHour: Int

  public var morningStartMinute: Int
  public var afternoonStartMinute: Int
  public var eveningStartMinute: Int
  public var nightStartMinute: Int

  public var morningConfiguration: TimeModeConfiguration
  public var afternoonConfiguration: TimeModeConfiguration
  public var eveningConfiguration: TimeModeConfiguration
  public var nightConfiguration: TimeModeConfiguration

  public init() {
    self.morningStartHour = TimeMode.morning.defaultStartHour
    self.afternoonStartHour = TimeMode.afternoon.defaultStartHour
    self.eveningStartHour = TimeMode.evening.defaultStartHour
    self.nightStartHour = TimeMode.night.defaultStartHour

    self.morningStartMinute = 0
    self.afternoonStartMinute = 0
    self.eveningStartMinute = 0
    self.nightStartMinute = 0

    self.morningConfiguration = TimeModeConfiguration(for: .morning)
    self.afternoonConfiguration = TimeModeConfiguration(for: .afternoon)
    self.eveningConfiguration = TimeModeConfiguration(for: .evening)
    self.nightConfiguration = TimeModeConfiguration(for: .night)
  }

  public func configuration(for timeMode: TimeMode) -> TimeModeConfiguration {
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

  public mutating func setConfiguration(_ configuration: TimeModeConfiguration, for timeMode: TimeMode) {
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

  public func startHour(for timeMode: TimeMode) -> Int {
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

  public mutating func setStartHour(_ hour: Int, for timeMode: TimeMode) {
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

  public func startMinute(for timeMode: TimeMode) -> Int {
    switch timeMode {
    case .morning:
      return morningStartMinute
    case .afternoon:
      return afternoonStartMinute
    case .evening:
      return eveningStartMinute
    case .night:
      return nightStartMinute
    }
  }

  public mutating func setStartMinute(_ minute: Int, for timeMode: TimeMode) {
    switch timeMode {
    case .morning:
      morningStartMinute = minute
    case .afternoon:
      afternoonStartMinute = minute
    case .evening:
      eveningStartMinute = minute
    case .night:
      nightStartMinute = minute
    }
  }
}
