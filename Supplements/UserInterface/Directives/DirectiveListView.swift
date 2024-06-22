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
                if viewModel.directives.isEmpty {
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
                        ForEach(viewModel.directives, id: \.hashValue) { directive in
                            Section {
                                DirectiveCell(directive: directive)
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
