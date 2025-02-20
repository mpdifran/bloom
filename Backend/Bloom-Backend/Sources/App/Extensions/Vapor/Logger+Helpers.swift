//
//  Logger+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-11.
//

import Foundation
import Vapor

extension Logger {

  func info(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
    self.info(Logger.Message(stringLiteral: message), file: file, function: function, line: line)
  }

  func warning(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
    self.warning(Logger.Message(stringLiteral: message), file: file, function: function, line: line)
  }

  func error(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
    self.error(Logger.Message(stringLiteral: message), file: file, function: function, line: line)
  }

  func error(_ error: Error, file: String = #fileID, function: String = #function, line: UInt = #line) {
    self.error(Logger.Message(stringLiteral: error.localizedDescription), file: file, function: function, line: line)
  }
}
