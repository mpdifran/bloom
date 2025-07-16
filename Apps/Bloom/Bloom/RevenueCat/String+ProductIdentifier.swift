//
//  String+ProductIdentifier.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-15.
//

import Foundation

extension String {
  enum ProductIdentifier {
    static let all: [String] = [
      .ProductIdentifier.monthly,
      .ProductIdentifier.yearly
    ]

    static let monthly = "bloom_pro_monthly"
    static let yearly = "bloom_pro_yearly"
  }
}
