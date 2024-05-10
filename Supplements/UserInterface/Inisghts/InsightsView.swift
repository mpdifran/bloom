//
//  InsightsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct InsightsView: View {

    @State private var isLoading = false
    @State private var error: Error?

    @ObservedObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ContentUnavailableView("Loading Insights", systemImage: "heart.text.square")
                } else if viewModel.insights == nil {
                    ContentUnavailableView(label: {
                        Label("No Insights Available", systemImage: "heart.text.square")
                    }, actions: {
                        Button("Reload", systemImage: "arrow.counterclockwise") {
                            Task { await loadData() }
                        }
                    })
                } else {
                    List {
                        Text("Content")
                    }
                }
            }
            .navigationTitle("Insights")
        }
        .task {
            await loadData()
        }
        .tabItem {
            Label("Insights", systemImage: "heart.text.square")
        }
    }
}

private extension InsightsView {

    func loadData() async {
        guard viewModel.insights == nil else { return }

        await MainActor.run { isLoading = true }
        do {
            try await viewModel.loadData()
        } catch {
            self.error = error
        }
        await MainActor.run { isLoading = false }
    }
}

#Preview {
    TabView {
        InsightsView()
    }
}
