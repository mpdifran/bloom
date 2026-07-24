//
//  MonitorView.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck

/// Displays health monitor states. Pushed onto the You tab's navigation stack.
struct MonitorView: View {

  /// When set, the view auto-navigates to this monitor's detail on appear (used for notification deep links).
  let initialDetail: MonitorType?

  @State private var viewModel = MonitorViewModel.shared
  @State private var presentedNavigationDestination: AnyView?
  @State private var presentedSheet: AnyView?

  @ObservedObject private var entitlementController = EntitlementController.shared

  init(initialDetail: MonitorType? = nil) {
    self.initialDetail = initialDetail
  }

  var body: some View {
    contentView
      .navigationTitle("Monitor")
      .toolbar {
        if entitlementController.hasBloomPro == true {
          ToolbarItem(placement: .primaryAction) {
            Button {
              presentedSheet = MonitorSettingsView().asAny
            } label: {
              Image(systemSymbol: .sliderHorizontal3)
                .bold()
            }
            .buttonStyle(.plain)
          }
        }
      }
      .navigationDestination($presentedNavigationDestination)
      .sheet($presentedSheet)
      .task {
        // Load cached data first for instant display
        await viewModel.loadCached()
        viewModel.markAlertsAsSeen()

        // Only refresh if data is stale
        await viewModel.refreshIfNeeded()
        viewModel.markAlertsAsSeen()

        // Deep-link: forward to the requested monitor's detail
        if let initialDetail {
          navigateToDetails(for: initialDetail)
        }
      }
      .onAppear {
        TelemetryDeck.signal("View Monitor Tab")
      }
      .onForegroundTask {
        await viewModel.refreshIfNeeded()
        viewModel.markAlertsAsSeen()
      }
  }

  // MARK: - Content View

  @ViewBuilder
  private var contentView: some View {
    if entitlementController.hasBloomPro == true {
      monitorListContent
    } else {
      MonitorWelcomeView(presentedSheet: $presentedSheet)
    }
  }

  private var monitorListContent: some View {
    BloomScrollView(spacing: 16) {
      // Section 1: Monitors needing attention
      if !viewModel.monitorsNeedingAttention.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text("Needs Attention")
            .font(.headline)
            .padding(.horizontal)

          ForEach(viewModel.monitorsNeedingAttention) { result in
            MonitorCard(result: result)
              .onTapGesture {
                navigateToDetails(for: result.monitorType)
              }
          }
        }

      }

      // Section 2: Other monitors (good, encourage, unavailable)
      let otherMonitors = viewModel.results.filter { !$0.state.isConcerning }
      if !otherMonitors.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          // Only show header if there's also a "Needs Attention" section
          if !viewModel.monitorsNeedingAttention.isEmpty {
            Text("Other Monitors")
              .font(.headline)
              .padding(.horizontal)
          }

          ForEach(otherMonitors) { result in
            MonitorCard(result: result)
              .onTapGesture {
                navigateToDetails(for: result.monitorType)
              }
          }
        }
      }
    }
  }

  // MARK: - Navigation

  private func navigateToDetails(for monitorType: MonitorType) {
    switch monitorType {
    case .recovery:
      presentedNavigationDestination = RecoveryDetailView().asAny
    case .stress:
      presentedNavigationDestination = StressDetailView().asAny
    case .sleep:
      presentedNavigationDestination = SleepDetailView().asAny
    }
  }

}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    NavigationStack {
      MonitorView()
    }
  }
}
