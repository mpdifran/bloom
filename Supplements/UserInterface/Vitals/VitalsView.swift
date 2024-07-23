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
            }
            .navigationTitle("Vitals")
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
