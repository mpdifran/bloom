//
//  Logger+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-11.
//

import Foundation
import Vapor

extension Logger {

  func error(_ error: Error, file: String = #fileID, function: String = #function, line: UInt = #line) {
    self.error(.init(stringLiteral: error.localizedDescription), file: file, function: function, line: line)
  }
}
