//
//  ExternalHealthMetricPermissionManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-04.
//

import SwiftUI
import AppFoundations

private extension String {
  static let determinedPermissionIDs = "ExternalHealthMetricPermissionManager.determinedPermissionIDs"
}

@MainActor
final class ExternalHealthMetricPermissionManager: ObservableObject {
  static let shared = ExternalHealthMetricPermissionManager()

  @Storage(
    key: .determinedPermissionIDs,
    defaultValue: [String](),
    store: .group
  ) private var determinedPermissionIDs: [String]

  @AppStorage(.FeatureFlag.alwaysAskForAIGoalSettingPermission) private var alwaysAskForAIGoalSettingPermission = false

  private init() { }
}

extension ExternalHealthMetricPermissionManager {

  var undeterminedPermissions: [ExternalHealthMetricPermission] {
    ExternalHealthMetricPermission.all
      .filter { !determinedPermissionIDs.contains($0.id) }
  }

  var determinedPermissions: [ExternalHealthMetricPermission] {
    ExternalHealthMetricPermission.all
      .filter { determinedPermissionIDs.contains($0.id) }
  }

  var enabledPermissions: [ExternalHealthMetricPermission] {
    ExternalHealthMetricPermission.all
      .filter { getIsEnabled(for: $0) }
  }

  var permissionsDictionary: [String : String] {
    var result = [String : String]()
    for permission in ExternalHealthMetricPermission.all {
      result[permission.id] = getIsEnabled(for: permission) ? "Enabled" : "Disabled"
    }
    return result
  }

  func hasUndeterminedPermissions() -> Bool {
    if alwaysAskForAIGoalSettingPermission {
      return true
    }

    let determinedSet = determinedPermissionIDs.asSet()
    let currentSet = ExternalHealthMetricPermission.all.map(\.id).asSet()

    return currentSet != determinedSet
  }

  func markPermissionsAsDetermined(_ permissions: [ExternalHealthMetricPermission]) {
    var existingSet = determinedPermissionIDs.asSet()
    let newSet = permissions.map(\.id).asSet()
    existingSet.formUnion(newSet)
    self.determinedPermissionIDs = Array(existingSet)
  }
}

extension ExternalHealthMetricPermissionManager {

  func hasAllPermissionsEnabled(for permissions: [ExternalHealthMetricPermission]) -> Bool {
    permissions.allSatisfy { getIsEnabled(for: $0) }
  }

  func set(for permissions: [ExternalHealthMetricPermission], isEnabled: Bool) {
    permissions.forEach { set(isEnabled: isEnabled, for: $0) }
  }

  func getIsEnabled(for healthMetric: ExternalHealthMetricPermission) -> Bool {
    UserDefaults.group.bool(forKey: healthMetric.id)
  }

  func set(isEnabled: Bool, for healthMetric: ExternalHealthMetricPermission) {
    UserDefaults.group.set(isEnabled, forKey: healthMetric.id)
    objectWillChange.send()
  }
}
