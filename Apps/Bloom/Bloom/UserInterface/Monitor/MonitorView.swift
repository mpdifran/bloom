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

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading && !viewModel.hasLoaded {
          loadingView
        } else if viewModel.results.isEmpty {
          emptyView
        } else {
          contentView
        }
      }
      .navigationTitle("Monitor")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            presentedSheet = MonitorSettingsView().asAny
          } label: {
            Image(systemSymbol: .sliderHorizontal3)
              .bold()
          }
          .buttonStyle(.plain)
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

      // Then refresh with fresh data
      await viewModel.refresh()
    }
    .onAppear {
      TelemetryDeck.signal("View Monitor Tab")
    }
  }

  // MARK: - Content View

  private var contentView: some View {
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

      if viewModel.isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Updating...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
      }
    }
  }

  // MARK: - Loading View

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Analyzing your health data...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty View

  private var emptyView: some View {
    VStack(spacing: 16) {
      Image(systemSymbol: .waveformPathEcg)
        .font(.system(size: 64))
        .foregroundStyle(.secondary)

      Text("No Monitor Data")
        .font(.headline)

      Text("We need a few days of health data to start monitoring your recovery, stress, and sleep patterns.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Button {
        Task {
          await viewModel.refresh()
        }
      } label: {
        Text("Try Again")
          .fontWeight(.medium)
      }
      .buttonStyle(.borderedProminent)
      .padding(.top, 8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
