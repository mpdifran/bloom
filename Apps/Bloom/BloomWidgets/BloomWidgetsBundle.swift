//
//  BloomWidgetsBundle.swift
//  BloomWidgets
//
//  Created by Mark DiFranco on 2025-10-12.
//

import WidgetKit
import SwiftUI
import BloomFoundation

@main
struct BloomWidgetsBundle: WidgetBundle {
  var body: some Widget {
    ActionControl()
    BudSummaryWidget()
    TodayInsightWidget()
    HealthInsightWidget()
    LogMealWidget()
    LogActionsWidget()
    GoalWidget()
  }
}
