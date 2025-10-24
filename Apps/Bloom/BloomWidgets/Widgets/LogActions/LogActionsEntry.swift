//
//  LogActionsEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-24.
//

import Foundation
import WidgetKit

struct LogActionsEntry: TimelineEntry {
  let date: Date
  let actions: [ActionType]
}
