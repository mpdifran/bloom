//
//  ActionsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI

struct ActionsView: View {

    @State private var showAllDataView = false
    @State private var presentedCardSheet: AnyView?

    @StateObject private var viewModel = ActionsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ActionStatusCell(
                        title: "Log Weight",
                        systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
                        latestValue: viewModel.weightDetails?.displayString,
                        latestTimestamp: viewModel.weightDetails?.timestampString
                    )
                    .tint(.indigo)
                    .onTapGesture {
                        presentedCardSheet = BodyWeightActionCardView().asAny
                    }

                    ActionStatusCell(
                        title: "Log Blood Pressure",
                        systemImage: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
                        latestValue: viewModel.bloodPressureDetails?.displayString,
                        latestTimestamp: viewModel.bloodPressureDetails?.timestampString
                    )
                    .tint(.pink)
                    .onTapGesture {
                        presentedCardSheet = BloodPressureActionCardView().asAny
                    }

                    ActionStatusCell(
                        title: "Log Water",
                        systemImage: "waterbottle.fill",
                        latestValue: viewModel.waterDetails?.displayString,
                        latestTimestamp: viewModel.waterDetails?.timestampString
                    )
                    .tint(.blue)
                    .onTapGesture {
                        presentedCardSheet = WaterActionCardView().asAny
                    }

                    ActionStatusCell(
                        title: "Log Bowel Movement",
                        systemImage: "toilet.fill",
                        latestValue: viewModel.bowelMovementDetails?.displayString,
                        latestTimestamp: viewModel.bowelMovementDetails?.timestampString
                    )
                    .tint(.brown)
                    .onTapGesture {
                        presentedCardSheet = BowelMovementActionCardView().asAny
                    }
                }
                .padding()
                .onAppear {
                    viewModel.observeData()
                }
            }
            .navigationTitle("Actions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showAllDataView = true
                    }, label: {
                        Text("All Data")
                    })
                }
            }
            .navigationDestination(isPresented: $showAllDataView) {
                AllActionDataListView()
            }
            .gradientRootBackground()
        }
        .sheet($presentedCardSheet)
        .tabItem {
            Label("Actions", systemImage: "plus.app")
        }
    }
}

#Preview {
    TabView {
        ActionsView()
    }
}
