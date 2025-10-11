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
import Combine
import CoreHealth

extension TodayView {
  @MainActor @Observable
  final class ViewModel {
    static let shared = ViewModel()

    var hasBloomPlus: Bool = false

    private let todayInsightsManager = TodayInsightsManager.shared
    private var entitlementCancellable: AnyCancellable?

    private init() {
      checkEntitlement()

      Task {
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

  var isLoadingContent: Bool {
    todayInsightsManager.isLoadingContent
  }

  var todayContent: TodayContentDTO? {
    todayInsightsManager.todayContent
  }

  var hasLoadError: Bool {
    todayInsightsManager.hasLoadError
  }

  var budState: TodayReportResponse.BudState? {
    todayInsightsManager.budState
  }

  func checkEntitlement() {
    hasBloomPlus = EntitlementController.shared.hasBloomPro == true
  }

  func loadContent() async {
    await todayInsightsManager.refreshContentIfNeeded()
  }

  func refreshContent() {
    Task {
      await todayInsightsManager.refreshContentIfNeeded()
    }
  }

  func requestContentIfNeeded() async {
    await todayInsightsManager.refreshContentIfNeeded()
  }

  func retryLoadContent() async {
    await todayInsightsManager.forceRefreshContent()
  }

  func observeLoadingState() async {
    // No longer needed as we directly access the manager's properties
  }

  func observeErrors() async {
    // No longer needed as we directly access the manager's properties
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

    case .phaseTip:
      guard let phaseTip = todayContent?.periodInsight?.phaseTip else { return nil }
      return .text(phaseTip)

    case .periodForecast:
      guard let periodForecast = todayContent?.periodInsight?.periodForecast else { return nil }
      return .text(periodForecast)

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
