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
        ToolbarItem(placement: .primaryAction) {
          refreshButton
        }
      }
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
    .refreshable {
      await viewModel.refresh()
    }
    .onAppear {
      TelemetryDeck.signal("View Monitor Tab")
    }
  }

  // MARK: - Content View

  private var contentView: some View {
    BloomScrollView(spacing: 16) {
      statusHeader

      ForEach(MonitorType.allCases, id: \.self) { monitorType in
        if let result = viewModel.result(for: monitorType) {
          MonitorCard(result: result)
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

  private var statusHeader: some View {
    VStack(spacing: 8) {
      Image(systemSymbol: statusIcon)
        .font(.system(size: 48))
        .foregroundStyle(statusColor)

      Text(viewModel.statusSummary)
        .font(.headline)
        .multilineTextAlignment(.center)

      if let error = viewModel.error {
        Text(error.localizedDescription)
          .font(.caption)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
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

  // MARK: - Toolbar

  private var refreshButton: some View {
    Button {
      Task {
        await viewModel.refresh()
      }
    } label: {
      if viewModel.isLoading {
        ProgressView()
      } else {
        Image(systemSymbol: .arrowClockwise)
      }
    }
    .disabled(viewModel.isLoading)
  }

  // MARK: - Status Helpers

  private var statusIcon: SFSymbol {
    if viewModel.isAllGood {
      return .checkmarkCircleFill
    } else if viewModel.monitorsNeedingAttention.contains(where: { $0.state == .off }) {
      return .exclamationmarkTriangleFill
    } else {
      return .exclamationmarkCircleFill
    }
  }

  private var statusColor: Color {
    if viewModel.isAllGood {
      return .green
    } else if viewModel.monitorsNeedingAttention.contains(where: { $0.state == .off }) {
      return .red
    } else {
      return .orange
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    MonitorView()
  }
}
