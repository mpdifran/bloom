//
//  MonitorSummarySection.swift
//  Bloom
//
//  Created by Claude on 2026-07-23.
//

import SwiftUI
import AppUI
import BloomFoundation

/// A row of compact health-monitor cards on the You tab. Tapping any card opens the full Monitor view.
struct MonitorSummarySection: View {

  @Binding var presentedNavigationDestination: AnyView?

  @State private var viewModel = MonitorViewModel.shared

  var body: some View {
    HStack(spacing: 12) {
      MiniMonitorCard(type: .recovery, state: viewModel.result(for: .recovery)?.state ?? .unavailable)
      Divider()
      MiniMonitorCard(type: .sleep, state: viewModel.result(for: .sleep)?.state ?? .unavailable)
      Divider()
      MiniMonitorCard(type: .stress, state: viewModel.result(for: .stress)?.state ?? .unavailable)
    }
    .cardContainer()
    .selectable()
    .onTapGesture {
      presentedNavigationDestination = MonitorView().asAny
    }
    .task {
      // Populate the cards the same way the Monitor tab used to.
      await viewModel.loadCached()
      await viewModel.refreshIfNeeded()
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MonitorSummarySection(presentedNavigationDestination: .constant(nil))
    }
  }
}
