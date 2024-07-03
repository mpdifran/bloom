//
//  DirectiveListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import SwiftUI
import AppUI

struct DirectiveListView: View {
    @ObservedObject private var viewModel = DirectiveListViewModel.shared

    @State private var error: Error?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sleepActivities.isEmpty {
                    ContentUnavailableView {
                        Label("No Actions", systemImage: "figure.run")
                    } description: {
                        Text("There are currently no actions for you.")
                    } actions: {
                        Button("Reload", systemImage: "arrow.clockwise") {
                            Task {
                                do {
                                    try await SleepProgramCoordinator.shared.sleepProgramUpdate()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .buttonStyle(.tertiary)
                    }
                } else {
                    List {
                        ForEach(viewModel.sleepActivities) { sleepActivity in
                            Section {
                                DirectiveCell(sleepActivity: sleepActivity)
                            }
                        }
                    }
                    .refreshable {
                        do {
                            try await SleepProgramCoordinator.shared.sleepProgramUpdate()
                        } catch {
                            self.error = error
                        }
                    }
                }
            }
            .navigationTitle("Actions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset Assistant", systemImage: "sparkles") {
                        SleepProgramCoordinator.shared.resetAssistant()
                    }
                }
            }
        }
        .alert(error: $error)
        .tabItem {
            Label("Actions", systemImage: "figure.run")
        }
    }
}

#Preview {
    TabView {
        DirectiveListView()
    }
}
