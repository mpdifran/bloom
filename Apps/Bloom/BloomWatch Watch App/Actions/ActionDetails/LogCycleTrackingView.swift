//
//  LogCycleTrackingView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-06.
//

import SwiftUI
import HealthKit
import HealthKitUI
import CoreHealth
import TelemetryDeck
import BloomFoundation

struct LogCycleTrackingView: View {
  let performDismiss: (() -> Void)?

  @State private var flowType: HKCategoryValueVaginalBleeding = .none
  @State private var showingSaveConfirmation = false
  @State private var isSaving = false
  @State private var permissionState: PermissionState = .checking
  @State private var triggerHealthPermission = false

  private let healthStore = HealthPermissionChecker.shared.healthStore
  private let menstrualType = HKCategoryType(.menstrualFlow)

  private let allFlowTypes: [HKCategoryValueVaginalBleeding] = [.none, .light, .medium, .heavy]

  var body: some View {
    Group {
      switch permissionState {
      case .checking:
        ProgressView()
      case .authorized:
        authorizedContent
      case .denied:
        deniedContent
      }
    }
    .navigationTitle("Log Period")
    .navigationBarTitleDisplayMode(.inline)
    .frame(maxWidth: .infinity)
    .background(.black)
    .overlay {
      if showingSaveConfirmation {
        saveConfirmationOverlay
      }
    }
    .healthDataAccessRequest(
      store: healthStore,
      shareTypes: [menstrualType],
      readTypes: [menstrualType],
      trigger: triggerHealthPermission
    ) { result in
      Task { @MainActor in
        switch result {
        case .success:
          permissionState = .authorized
        case .failure:
          permissionState = .denied
        }
      }
    }
    .task {
      await checkPermission()
    }
  }
}

// MARK: - Permission State

private extension LogCycleTrackingView {

  enum PermissionState {
    case checking
    case authorized
    case denied
  }

  func checkPermission() async {
    do {
      let status = try await HealthPermissionChecker.shared.checkAccess(
        readTypes: [menstrualType],
        writeTypes: [menstrualType]
      )

      if status == .shouldRequest {
        triggerHealthPermission.toggle()
      } else {
        // Check if write access is denied
        let authStatus = healthStore.authorizationStatus(for: menstrualType)
        if authStatus == .sharingDenied {
          permissionState = .denied
        } else {
          permissionState = .authorized
        }
      }
    } catch {
      permissionState = .denied
    }
  }
}

// MARK: - Authorized Content

private extension LogCycleTrackingView {

  var authorizedContent: some View {
    List {
      ForEach(allFlowTypes, id: \.self) { flow in
        Button {
          Task { await save(flow: flow) }
        } label: {
          HStack(spacing: 12) {
            flowIndicator(for: flow)
              .frame(width: 30, height: 42)
            Text(flow.name)
              .font(.body)
              .fontDesign(.rounded)
              .bold()
          }
        }
        .disabled(isSaving)
      }
    }
    .listStyle(.carousel)
  }

  func flowIndicator(for flow: HKCategoryValueVaginalBleeding) -> some View {
    Capsule()
      .fill(.white)
      .overlay {
        VStack {
          switch flow {
          case .light:
            Circle()
              .fill(.mutedPink)
              .padding(6)
          case .medium:
            Circle()
              .fill(.mutedPink)
              .padding(3)
          case .heavy:
            Circle()
              .fill(.mutedPink)
          case .none, .unspecified:
            EmptyView()
          @unknown default:
            EmptyView()
          }
          Spacer()
        }
        .padding(4)
      }
  }

  func save(flow: HKCategoryValueVaginalBleeding) async {
    guard !isSaving, !showingSaveConfirmation else { return }

    isSaving = true

    do {
      try await HealthStoreModifier.shared.log(flowType: flow, date: .now)

      isSaving = false
      SoundPlayer.playLogHealthData()
      TelemetryDeck.signal("Watch Log Period")

      withAnimation {
        showingSaveConfirmation = true
      }

      try? await Task.sleep(for: .seconds(1))
      performDismiss?()
    } catch {
      isSaving = false
    }
  }
}

// MARK: - Denied Content

private extension LogCycleTrackingView {

  var deniedContent: some View {
    ScrollView {
      VStack(spacing: 12) {
        Image(systemName: "lock.shield")
          .font(.system(size: 32))
          .foregroundStyle(.secondary)

        Text("Period tracking requires access to Health data. Please enable it in the Health app on your iPhone.")
          .font(.caption)
          .fontDesign(.rounded)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
      }
      .padding()
    }
  }
}

// MARK: - Overlays

private extension LogCycleTrackingView {

  var saveConfirmationOverlay: some View {
    VStack {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 50))
        .foregroundStyle(.green)

      Text("Saved")
        .font(.headline)
        .bold()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      LogCycleTrackingView(performDismiss: nil)
    }
  }
}
