//
//  CalendarPreferenceManager.swift
//  Bloom
//
//  Created by Assistant on 2025-09-09.
//

import Foundation
import Combine
@preconcurrency import EventKit

@Observable
final class CalendarPreferenceManager {
  static let shared = CalendarPreferenceManager()
  
  private let storageKey = "CalendarPreferences.selectedIdentifiers"
  
  var selectedCalendarIdentifiers: Set<String> = [] {
    didSet {
      saveToUserDefaults()
    }
  }
  
  private var cancellables = Set<AnyCancellable>()
  
  private init() {
    loadFromUserDefaults()
    
    // If no calendars selected, initialize with all calendars
    Task { @MainActor in
      await initializeIfNeeded()
    }
  }
  
  private func loadFromUserDefaults() {
    if let storedArray = UserDefaults.group.object(forKey: storageKey) as? [String] {
      selectedCalendarIdentifiers = Set(storedArray)
    }
  }
  
  private func saveToUserDefaults() {
    UserDefaults.group.set(Array(selectedCalendarIdentifiers), forKey: storageKey)
  }
  
  @MainActor
  private func initializeIfNeeded() async {
    // Check if we have calendar permission
    guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return }
    
    // If no calendars are selected, select all
    if selectedCalendarIdentifiers.isEmpty {
      let calendars = CalendarManager.shared.getAllCalendars()
      if !calendars.isEmpty {
        selectedCalendarIdentifiers = Set(calendars.map { $0.calendarIdentifier })
      }
    }
  }
}