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

  @ObservedObject private var manager = ExternalHealthMetricPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          headerSection
          permissionsSection
        }
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Health & Privacy")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Don't Allow") {
            Task {
              await recordPermissions(didAllow: false)
            }
          }
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Allow") {
            Task {
              await recordPermissions(didAllow: true)
            }
          }
          .bold()
          .disabled(!hasAtLeastOnePermissionEnabled)
        }
      }
      .shelf {
        enableAllButton
      }
    }
    .animation(.default, value: showAllPermissions)
    .animation(.default, value: hasAtLeastOnePermissionEnabled)
    .presentationCompactAdaptation(.fullScreenCover)
    .confirmationDialog($confirmationDialogDetails)
    .tint(.mutedBlue)
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

  var canShowAllPermissions: Bool {
    let hasDeterminedPermissions = manager.determinedPermissions.isNotEmpty
    return mode == .onlyUndetermined && !showAllPermissions && hasDeterminedPermissions
  }

  var hasAtLeastOnePermissionEnabled: Bool {
    permissions.first(where: { manager.getIsEnabled(for: $0) }) != nil
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

          Text("External Health Sharing")
            .font(.title3)
        }

        Text("Please select which health data you want to share with us. Your health data is not tied to any personally identifiable information, and is not stored on our servers.")
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)

        Divider()
      }
      .horizontalAlignment(.leading)
      .padding(.horizontal)
      .padding(.top)

      HStack {
        Link("Privacy Policy", destination: .privacyPolicy)
          .bold()
          .frame(minHeight: 50)
          .horizontallyCentered()

        Divider()
          .padding(.vertical, 4)

        Link("Questions? Email Us!", destination: .emailBloom)
          .bold()
          .frame(minHeight: 50)
          .horizontallyCentered()
      }
    }
    .bold()
    .fontDesign(.rounded)
    .multilineTextAlignment(.center)
    .cardContainer(includePadding: false)
  }

  @ViewBuilder
  var permissionsSection: some View {
    if permissions.isNotEmpty {
      VStack {
        ForEachEnumerated(permissions) { index, permission in
          if index != 0 {
            Divider()
          }
          ExternalHealthMetricPermissionCell(permission: permission)
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

  var enableAllButton: some View {
    Group {
      if manager.hasAllPermissionsEnabled(for: permissions) {
        Button {
          manager.set(for: permissions, isEnabled: false)
          turnOnAllToggle.toggle()
        } label: {
          Text("Turn Off All")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      } else {
        Button {
          manager.set(for: permissions, isEnabled: true)
          turnOnAllToggle.toggle()
        } label: {
          Text("Turn On All")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
    }
    .sensoryFeedback(.impact, trigger: turnOnAllToggle)
  }
}

private extension ExternalHealthPrivacyView {

  func recordPermissions(didAllow: Bool) async {
    if !didAllow {
      manager.set(for: permissions, isEnabled: false)
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
  ExternalHealthPrivacyView(mode: .all) {

  }
}
