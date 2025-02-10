//
//  AIGeneratedReportView.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-02-08.
//

import SwiftUI
import AdminBloomModel

struct AIGeneratedReportView: View {
  @ObservedObject private var viewModel: AIGeneratedReportViewModel
  
  init(viewModel: AIGeneratedReportViewModel) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    VStack {
      disclaimerView
      reportView
      actionMenu
    }
    .frame(maxWidth: 100)
  }
  
  @ViewBuilder
  private var reportView: some View {
    switch viewModel.accuracyReportState {
    case .notApplicable:
      EmptyView()
    case .pendingFetch:
      FuturisticCircularWrapperView {
        ProgressView()
      }
      .task { await viewModel.fetchAccuracyReport() }
    case .fetching:
      FuturisticCircularWrapperView {
        ProgressView()
      }
    case .noReportAvailable:
      FuturisticCircularWrapperView { Text("N/A") }
    case .fetched(let adminAccuracyReport):
      FuturisticCircularWrapperView {
        fetchedReportView(report: adminAccuracyReport)
      }
    }
  }
  
  @ViewBuilder
  private var disclaimerView: some View {
    if let disclaimer = viewModel.disclaimer {
      Text(disclaimer.text)
        .foregroundStyle(disclaimer.color)
        .font(.footnote)
    }
  }
  
  @ViewBuilder
  private var actionMenu: some View {
    switch viewModel.accuracyReportState {
    case .noReportAvailable, .fetched:
      Menu {
        Button("Regenerate report") { }
      } label: {
        Image("ellipsis.circle")
      }
      .menuStyle(.borderlessButton)
    default:
      EmptyView()
    }
  
  }
  
  private func fetchedReportView(report: AdminAccuracyReport) -> some View {
    Text(report.accuracyScore, format: .number.precision(.fractionLength(0)))
  }
}


private struct FuturisticCircularWrapperView<Content: View>: View {
  let contentBuilder: () -> Content
  
  init(@ViewBuilder contentBuilder: @escaping () -> Content) {
    self.contentBuilder = contentBuilder
  }
  
  var body: some View {
    contentBuilder()
      .font(.system(size: 24, weight: .bold, design: .monospaced))
      .foregroundStyle(LinearGradient(
        gradient: Gradient(colors: [.cyan, .blue, .purple]),
        startPoint: .leading,
        endPoint: .trailing
      ))
      .padding()
      .background(
        Circle()
          .fill(.ultraThinMaterial)
          .shadow(color: .cyan.opacity(0.8), radius: 10, x: 0, y: 0)
      )
      .overlay(
        Circle()
          .stroke(LinearGradient(
            gradient: Gradient(colors: [.cyan, .purple]),
            startPoint: .leading,
            endPoint: .trailing
          ), lineWidth: 1)
      )
      .opacity(0.8)
  }
}
