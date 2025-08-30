//
//  TodayViewModel.swift
//  Bloom
//
//  Created by Assistant on 2025-08-29.
//

import Foundation
import SwiftUI
import DataContainer
import BloomModel
import SwiftData
import Combine

extension TodayView {
  @MainActor @Observable
  final class ViewModel {
    var isLoadingContent = false
    var todayContent: TodayContentDTO?
    var hasBloomPlus: Bool = false
    var hasLoadError = false

    private let contentModelActor = TodayContentModelActor.standard()
    private var entitlementCancellable: AnyCancellable?

    init() {
      Task {
        checkEntitlement()
        await loadContent()
      }
      
      Task {
        await observeLoadingState()
      }
      
      Task {
        await observeErrors()
      }
      
      // Observe entitlement changes
      observeEntitlementChanges()
    }
  }
}

extension TodayView.ViewModel {

  var budState: TodayReportResponse.BudState? {
    guard let budStateString = todayContent?.budState else { return nil }
    return TodayReportResponse.BudState(rawValue: budStateString)
  }

  func checkEntitlement() {
    hasBloomPlus = EntitlementController.shared.hasBloomPro == true
  }
  
  func loadContent() async {
    do {
      todayContent = try await contentModelActor.fetchContent(for: Date())
      hasLoadError = false
    } catch {
      print("Failed to load today content: \(error)")
      hasLoadError = false // Don't show error for local fetch failures
    }
  }
  
  func refreshContent() {
    Task {
      await loadContent()
    }
  }
  
  func requestContentIfNeeded() async {
    hasLoadError = false
    await TodayContentCoordinator.shared.loadContentIfNeeded()
    // Reload content after the coordinator finishes
    await loadContent()
  }
  
  func retryLoadContent() async {
    hasLoadError = false
    // Force a reload attempt
    await TodayContentCoordinator.shared.loadContentIfNeeded()
    await loadContent()
  }
  
  func observeLoadingState() async {
    for await isLoading in await TodayContentCoordinator.shared.isLoadingContentStream {
      await MainActor.run {
        self.isLoadingContent = isLoading
      }
      
      // When loading finishes, refresh the content
      if !isLoading {
        await loadContent()
      }
    }
  }
  
  func observeErrors() async {
    for await error in await TodayContentCoordinator.shared.errorStream {
      await MainActor.run {
        self.hasLoadError = error != nil
      }
    }
  }
  
  func observeEntitlementChanges() {
    // Listen for entitlement changes using Combine
    entitlementCancellable = EntitlementController.shared.$hasBloomPro
      .dropFirst() // Skip the initial value
      .removeDuplicates()
      .sink { [weak self] newValue in
        guard let self = self else { return }
        
        let wasBloomPlus = self.hasBloomPlus
        let isBloomPlus = newValue == true
        self.hasBloomPlus = isBloomPlus
        
        // If user just got Bloom Plus, immediately load content
        if !wasBloomPlus && isBloomPlus {
          Task {
            await self.requestContentIfNeeded()
          }
        }
      }
  }
  
  func getSectionContent(for section: TodaySection) -> SectionContent? {
    switch section {
    case .todaysAdvice:
      guard let advice = todayContent?.todaysAdvice else { return nil }
      return .text(advice)
      
    case .insights:
      guard let insights = todayContent?.insights, !insights.isEmpty else { return nil }
      return .insights(insights.map { insight in
        TodayReportResponse.HealthInsight(
          title: insight.title,
          body: insight.body,
          priority: insight.priority
        )
      })
      
    case .sleepDetails:
      guard let details = todayContent?.sleepDetails else { return nil }
      return .text(details)
      
    case .tonightsSleep:
      guard let recommendations = todayContent?.tonightsSleepRecommendations else { return nil }
      return .text(recommendations)
      
    case .goals:
      // This will be handled by existing habits section in TodayView
      return .local
      
    case .reminders:
      // This will be handled by existing reminders section in TodayView
      return .local
      
    case .todaysEvents, .tomorrowsEvents:
      // These will be handled by calendar integration
      return .local
      
    case .todaysWeather, .tomorrowsWeather:
      // These will be handled by weather integration
      return .local
    }
  }
  
  enum SectionContent {
    case text(String)
    case insights([TodayReportResponse.HealthInsight])
    case local // Indicates content comes from local data sources
  }
}
