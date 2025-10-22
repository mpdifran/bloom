//
//  TodayInsightEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import Foundation
import WidgetKit
import SwiftUI
import SFSafeSymbols

struct TodayInsightEntry: TimelineEntry {
  enum ContentType {
    case advice
    case sleep
  }

  let date: Date
  var relevance: TimelineEntryRelevance?

  // Display fields
  let title: String
  let content: String
  let symbol: SFSymbol
  let color: Color
  let contentType: ContentType

  // State flags
  let isLoading: Bool
  let hasError: Bool
  let isSubscribed: Bool
}
