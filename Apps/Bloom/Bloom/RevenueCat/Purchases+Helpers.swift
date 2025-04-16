//
//  Purchases+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-14.
//

import RevenueCat

private extension String {
  static let revenueCatPublicAPIKey = "appl_TarcsGdjyMRvzKeiDYYrxvhAZVo"
}

extension Purchases {

  static func configure() {
    #if DEBUG
    Purchases.logLevel = .error
    #endif
    Purchases.configure(withAPIKey: .revenueCatPublicAPIKey, appUserID: UserID.value)
  }
}
