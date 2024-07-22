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
            List {
                Section("Today") {
                    if let status = viewModel.hrvStatus {
                        VitalStatusCell(
                            title: status.name,
                            statusValue: status.value,
                            mode: status.mode
                        )
                    }
                    if let status = viewModel.sleepStatus {
                        NavigationLink {
                            TodayView()
                        } label: {
                            VitalStatusCell(
                                title: status.name,
                                statusValue: status.value,
                                mode: status.mode
                            )
                        }
                    }
                    if let status = viewModel.rhrStatus {
                        VitalStatusCell(
                            title: status.name,
                            statusValue: status.value,
                            mode: status.mode
                        )
                    }
                }
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
