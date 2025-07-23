//
//  MorningReportView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth
import AppUI

struct MorningReportView: View {
  @State private var viewModel = ViewModel()

  @State private var presentedSheet: AnyView?
  @State private var presentedNavPush: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView(padding: .vertical) {
        TodaysDateView()
          .padding(.horizontal)
        alertsSection
      }
      .navigationTitle("Morning Report")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
      }
      .sheet($presentedSheet)
      .navigationDestination($presentedNavPush)
    }
  }
}

private extension MorningReportView {

  @ViewBuilder
  var alertsSection: some View {
    if viewModel.alerts.isNotEmpty {
      ReportTitledSection("Alerts", includeExtraTitlePadding: true) {
        ScrollView(.horizontal) {
          HStack {
            ForEach(viewModel.alerts) { alert in
              switch alert {
              case .periodPrediction(let date):
                MorningReportPeriodPredictionAlertCell(predictedPeriodDate: date)
                  .onTapGesture {
                    presentedNavPush = MenstruationDetailView().asAny
                  }
              case .intenseActivity(let ratio):
                MorningReportAlertCell(
                  title: "Intense Activity Level (\(ratio.format(using: .oneDecimalPlace)))",
                  message: "Make sure to take a break today to recover.") {
                    Image(systemSymbol: .figureClimbing)
                      .font(.title)
                      .foregroundStyle(.tint)
                  }
                  .tint(.activityLevelIntense)
                  .onTapGesture {
                    presentedNavPush = ActivityLevelDetailsView().asAny
                  }
              case .sedentaryActivity:
                MorningReportAlertCell(
                  title: "Sedentary Activity Level",
                  message: "You've been sedentary for 3 days in a row.") {
                    Image(systemSymbol: .figureStand)
                      .font(.title)
                      .foregroundStyle(.tint)
                  }
                  .tint(.mutedYellow)
                  .onTapGesture {
                    presentedNavPush = ActivityLevelDetailsView().asAny
                  }
              }
            }
          }
          .scrollTargetLayout()
          .padding(.horizontal)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    MorningReportView()
  }
}
