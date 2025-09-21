//
//  TodayContentCoordinator.swift
//  Bloom
//
//  Created by Assistant on 2025-08-29.
//

import Foundation
import CoreHealth
import DataContainer
import BloomModel
import BloomFoundation
import TelemetryDeck

final actor TodayContentCoordinator {
  static let shared = TodayContentCoordinator()

  @AsyncStreamable private var isGeneratingContent = false
  @AsyncStreamable private var lastLoadError: Error? = nil

  private init() {}
}

extension TodayContentCoordinator {

  var isLoadingContentStream: AsyncStream<Bool> {
    $isGeneratingContent
  }

  var errorStream: AsyncStream<Error?> {
    $lastLoadError
  }

  func loadContentIfNeeded() async {
    guard await EntitlementController.shared.hasBloomPro == true else { return }
    guard !isGeneratingContent else { return }

    isGeneratingContent = true
    defer { isGeneratingContent = false }

    await TodayInsightsManager.shared.refreshContentIfNeeded()
  }

  func didDetectNewSleepData() async {
    guard await EntitlementController.shared.hasBloomPro == true else { return }
    guard !isGeneratingContent else { return }

    isGeneratingContent = true
    defer { isGeneratingContent = false }

    await TodayInsightsManager.shared.forceRefreshContent()
  }

  var isLoadingContent: Bool {
    isGeneratingContent
  }

  func deleteTodaysContent() async throws {
    // Clear UserDefaults storage
    UserDefaults.group.removeObject(forKey: "TodayInsightsManager.lastTodayContentRequestDate")
    UserDefaults.group.removeObject(forKey: "TodayInsightsManager.lastTodayContentResponse")
  }
}
