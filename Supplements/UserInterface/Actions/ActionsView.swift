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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Button(action: {
                        presentedCardSheet = BloodPressureActionCardView().asAny
                    }, label: {
                        Label("Log Blood Pressure", systemImage: "gauge.with.needle.fill")
                            .horizontallyCentered()
                    })
                    .buttonStyle(.tertiary)
                    .tint(.pink)

                    Button(action: {
                        presentedCardSheet = WaterActionCardView().asAny
                    }, label: {
                        Label("Log Water", systemImage: "waterbottle.fill")
                            .horizontallyCentered()
                    })
                    .buttonStyle(.tertiary)
                    .tint(.blue)

                    Button(action: {
                        presentedCardSheet = BowelMovementActionCardView().asAny
                    }, label: {
                        Label("Log Bowel Movement", systemImage: "toilet.fill")
                            .horizontallyCentered()
                    })
                    .buttonStyle(.tertiary)
                    .tint(.brown)
                }
                .padding()
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
