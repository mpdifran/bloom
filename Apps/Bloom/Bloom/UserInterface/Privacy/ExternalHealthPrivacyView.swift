//
//  ExternalHealthPrivacyView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-04.
//

import SFSafeSymbols
import SwiftUI
import Symbols
import AppUI
import TelemetryDeck
import BloomFoundation
import BloomUI

extension ExternalHealthPrivacyView {
  enum Mode {
    case onlyUndetermined
    case all
  }
}

struct ExternalHealthPrivacyView: View {
  let mode: Mode
  let onDismiss: () -> Void

  init(
    mode: Mode = .onlyUndetermined,
    onDismiss: @escaping () -> Void
  ) {
    self.mode = mode
    self.onDismiss = onDismiss
  }

  @State private var showAllPermissions = false
  @State private var turnOnAllToggle = false
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var permissionStates = [String: Bool]()

  @ObservedObject private var manager = ExternalHealthMetricPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          headerSection
          turnOnAllButton
          permissionsSection
        }
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Health & Privacy")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            Task {
              await recordPermissions(didAllow: false)
            }
          }
        }
      }
      .shelf {
        allowButton
      }
    }
    .animation(.default, value: showAllPermissions)
    .animation(.default, value: hasAtLeastOnePermissionEnabled)
    .animation(.default, value: permissionStates)
    .presentationCompactAdaptation(.fullScreenCover)
    .confirmationDialog($confirmationDialogDetails)
    .tint(.mutedBlue)
    .onAppear {
      for permission in ExternalHealthMetricPermission.all {
        permissionStates[permission.id] = manager.getIsEnabled(for: permission)
      }
    }
  }
}

private extension ExternalHealthPrivacyView {

  var permissions: [ExternalHealthMetricPermission] {
    switch mode {
    case .all:
      return ExternalHealthMetricPermission.all
    case .onlyUndetermined:
      if showAllPermissions {
        return ExternalHealthMetricPermission.all
      }
      if manager.undeterminedPermissions.isEmpty {
        return ExternalHealthMetricPermission.all
      }
      return manager.undeterminedPermissions
    }
  }

  var enabledPermissionsCount: Int {
    permissions.count(where: { getIsEnabled(for: $0) })
  }

  var canShowAllPermissions: Bool {
    let hasDeterminedPermissions = manager.determinedPermissions.isNotEmpty
    return mode == .onlyUndetermined && !showAllPermissions && hasDeterminedPermissions
  }

  var hasAllPermissionsEnabled: Bool {
    !permissions.contains(where: { !getIsEnabled(for: $0) })
  }

  var hasAtLeastOnePermissionEnabled: Bool {
    permissions.first(where: { getIsEnabled(for: $0) }) != nil
  }

  func getIsEnabled(for permission: ExternalHealthMetricPermission) -> Bool {
    permissionStates[permission.id, default: false]
  }

  func set(for permissions: [ExternalHealthMetricPermission], isEnabled: Bool) {
    for permission in permissions {
      permissionStates[permission.id] = isEnabled
    }
  }
}

private extension ExternalHealthPrivacyView {

  var headerSection: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemSymbol: .handRaisedCircleFill)
            .foregroundStyle(.white, .mutedBlue)
            .font(.system(size: 40))

          Text("External Data Sharing")
            .font(.title3)
        }

        Text("Please select which personal data you want to share. Your personal data is not tied to any personally identifiable information, and is not stored on our servers.")
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)

        Divider()
      }
      .padding(.horizontal)
      .padding(.top)

      privacyEmailView
        .padding(.horizontal)
    }
    .horizontalAlignment(.leading)
    .bold()
    .fontDesign(.rounded)
    .multilineTextAlignment(.center)
    .cardContainer(includePadding: false)
  }

  var privacyEmailView: some View {
    HStack {
      Link("Privacy Policy", destination: .privacyPolicy)
        .bold()
        .frame(height: 50)
        .horizontallyCentered()

      Link("Questions? Email Us!", destination: .emailBloom)
        .bold()
        .frame(height: 50)
        .horizontallyCentered()
    }
  }

  var turnOnAllButton: some View {
    VStack {
      if hasAllPermissionsEnabled {
        Text("Turn Off All")
      } else {
        Text("Turn On All")
      }
    }
    .horizontallyCentered()
    .bold()
    .foregroundStyle(.tint)
    .cardContainer()
    .onTapGesture {
      if hasAllPermissionsEnabled {
        set(for: permissions, isEnabled: false)
        turnOnAllToggle.toggle()
      } else {
        set(for: permissions, isEnabled: true)
        turnOnAllToggle.toggle()
      }
    }
    .sensoryFeedback(.impact, trigger: turnOnAllToggle)
  }

  @ViewBuilder
  var permissionsSection: some View {
    if permissions.isNotEmpty {
      VStack {
        ForEachEnumerated(permissions) { index, permission in
          if index != 0 {
            Divider()
          }
          ExternalHealthMetricPermissionCell(
            permission: permission,
            isEnabled: Binding($permissionStates[permission.id], replacingNilWith: false)
          )
        }
      }
      .cardContainer()

      if canShowAllPermissions {
        Button("Show All") {
          showAllPermissions = true
        }
        .bold()
      }
    }
  }

  var allowButton: some View {
    AsyncButton {
      await recordPermissions(didAllow: true)
    } label: {
      Text("Allow \(enabledPermissionsCount) \(enabledPermissionsCount == 1 ? "Category" : "Categories")")
        .contentTransition(.numericText(value: Double(enabledPermissionsCount)))
        .bold()
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }
}

private extension ExternalHealthPrivacyView {

  func recordPermissions(didAllow: Bool) async {
    if didAllow {
      for permission in ExternalHealthMetricPermission.all {
        let isAllowed = permissionStates[permission.id, default: false]
        manager.set(isEnabled: isAllowed, for: permission)
      }
    }

    manager.markPermissionsAsDetermined(permissions)

    TelemetryDeck.signal(
      "Updated External Health Permissions",
      parameters: manager.permissionsDictionary
    )

    dismiss()

    await Delay(300)

    onDismiss()
  }
}

#Preview {
  PreviewEnvironment {
    ExternalHealthPrivacyView(mode: .all) {

    }
  }
}
