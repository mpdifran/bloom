//
//  MonitorView.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck

/// Main view for the Monitor tab, displaying health monitor states.
struct MonitorView: View {

  @State private var viewModel = MonitorViewModel.shared
  @State private var presentedNavigationDestination: AnyView?
  @State private var presentedSheet: AnyView?

  @ObservedObject private var entitlementController = EntitlementController.shared
  @Environment(TabController.self) private var tabController

  var body: some View {
    NavigationStack {
      contentView
      .navigationTitle("Monitor")
      .toolbar {
        if entitlementController.hasBloomPro == true {
          ToolbarItem(placement: .cancellationAction) {
            Button {
              presentedSheet = MonitorSettingsView().asAny
            } label: {
              Image(systemSymbol: .sliderHorizontal3)
                .bold()
            }
            .buttonStyle(.plain)
          }
        }
        SettingsProfileViewToolbarButton()
      }
      .navigationDestination($presentedNavigationDestination)
      .sheet($presentedSheet)
    }
    .tabItem {
      Label("Monitor", systemSymbol: .waveformPathEcg)
    }
    .task {
      // Load cached data first for instant display
      await viewModel.loadCached()
      viewModel.markAlertsAsSeen()

      // Only refresh if data is stale
      await viewModel.refreshIfNeeded()
      viewModel.markAlertsAsSeen()
    }
    .onAppear {
      TelemetryDeck.signal("View Monitor Tab")
    }
    .onChange(of: tabController.activeTab) { _, newTab in
      if newTab == .monitor {
        viewModel.markAlertsAsSeen()
      }
    }
    .onForegroundTask {
      await viewModel.refreshIfNeeded()
      if tabController.activeTab == .monitor {
        viewModel.markAlertsAsSeen()
      }
    }
    .onChange(of: tabController.pendingMonitorNavigation) { _, newValue in
      if let monitorType = newValue {
        navigateToDetails(for: monitorType)
        tabController.pendingMonitorNavigation = nil
      }
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
    MonitorView()
  }
}
