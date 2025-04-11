//
//  CaseIterable+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-11.
//

import Foundation

extension CaseIterable where Self: RawRepresentable, Self.RawValue == String {

  static func stringCaseList() -> String {
    Self.allCases
      .map { $0.rawValue }
      .joined(separator: ", ")
  }
}
