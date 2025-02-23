//
//  Run.Status+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-22.
//

import OpenAIKit

extension Run.Status {
  var isActive: Bool {
    switch self {
    case .queued, .requiresAction, .inProgress:
      return true
    case .cancelling, .cancelled, .completed, .expired, .failed, .incomplete:
      return false
    }
  }
}
