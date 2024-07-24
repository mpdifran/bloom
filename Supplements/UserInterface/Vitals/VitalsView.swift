//
//  VitalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI

struct VitalsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    NavigationLink {
                        TodayView()
                    } label: {
                        VitalSummaryView(
                            hrvStatus: viewModel.hrvStatus,
                            sleepStatus: viewModel.sleepStatus,
                            rhrStatus: viewModel.rhrStatus
                        )
                    }
                    .buttonStyle(.plain)

                    if let energyBurnedSummary = viewModel.energyBurnedSummary {
                        EnergyBurnedSummaryCell(energyBurnedSummary: energyBurnedSummary)
                            .padding()
                    }
                }
            }
            .navigationTitle("Vitals")
            .background {
                LinearGradient(colors: [.remSleep.opacity(0.4), .remSleep.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .all)
            }
            .animation(.default, value: viewModel.hrvStatus)
            .animation(.default, value: viewModel.sleepStatus)
            .animation(.default, value: viewModel.rhrStatus)
        }
        .tabItem {
            Label("Vitals", systemImage: "bolt.heart")
        }
    }
}

#Preview {
    TabView {
        VitalsView()
    }
}
