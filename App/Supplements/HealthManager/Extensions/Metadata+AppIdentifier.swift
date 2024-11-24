//
//  NSPredicate+fromApp.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-24.
//

import Foundation
import HealthKit

// TODO: ZACH - Rename and use HealthMetadata keys
extension NSPredicate {
  static var fromApp: NSPredicate? {
    guard let appBundleIdentifier = Bundle.main.bundleIdentifier else { return nil }

    return HKQuery.predicateForObjects(
      withMetadataKey: "AppIdentifier",
      allowedValues: [appBundleIdentifier]
    )
  }
}
