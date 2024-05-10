//
//  OnboardingSupplementsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI
import AppUI

struct Token: Identifiable {
    var id: String { name }
    var name: String
}

struct OnboardingSupplementsView: View {

    let onContinue: () -> Void

    @ObservedObject private var viewModel = SupplementViewModel.shared

    @State private var searchText = ""
    @State private var error: Error?

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            List {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Selected") {
                        ForEach(viewModel.selectedSupplements, id: \.self) { supplement in
                            SupplementCell(
                                supplement: supplement,
                                isSelected: viewModel.isSupplementSelected(supplement)
                            )
                            .onTapGesture {
                                viewModel.toggleSelect(supplement: supplement)
                                feedbackGenerator.impactOccurred()
                            }
                        }
                    }
                }

                Section("All") {
                    ForEach(filteredSupplements, id: \.self) { supplement in
                        SupplementCell(
                            supplement: supplement,
                            isSelected: viewModel.isSupplementSelected(supplement)
                        )
                        .onTapGesture {
                            viewModel.toggleSelect(supplement: supplement)
                            feedbackGenerator.impactOccurred()
                        }
                    }
                }
            }
            .navigationTitle("Supplements")
            .shelf {
                VStack {
                    TextActionBar(
                        searchText: $searchText,
                        prompt: "What supplements do you take?",
                        systemImage: "cross.vial"
                    )

                    ProminentButton("Continue") {
                        onContinue()
                    }
                    .buttonBorderShape(.roundedRectangle(radius: 17))
                }
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
        .animation(.default, value: viewModel.selectedSupplements)
        .alert(error: $error)
        .task {
            do {
                try await loadSupplements()
            } catch {
                self.error = error
            }
        }
    }
}

private extension OnboardingSupplementsView {

    var filteredSupplements: [String] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedSearchText.isNotEmpty else { return viewModel.supplements }

        return viewModel.supplements.filter { supplement in
            supplement.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    func loadSupplements() async throws {
        try await viewModel.loadSupplements()
    }
}

#Preview {
    OnboardingSupplementsView { }
}
