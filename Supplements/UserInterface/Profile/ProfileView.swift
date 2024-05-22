//
//  ProfileView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-21.
//

import SwiftUI

struct ProfileView: View {

    @ObservedObject private var viewModel = ProfileViewModel.shared

    @State private var presentedSheet: AnyView?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    EmptyView()
                } header: {
                    ProfileHeaderView(name: $viewModel.name)
                        .textCase(.none)
                }

                Section {
                    if viewModel.userGoals.isEmpty {
                        Text("No Goals")
                    }
                    ForEach(viewModel.userGoals, id: \.self) { goal in
                        ProfileItemCell(title: goal)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    viewModel.userGoals = viewModel.userGoals.filter({ $0 != goal })
                                }
                            }
                    }
                    Button("Add Goal", systemImage: "plus") {
                        presentedSheet = NewProfileItemView(
                            itemName: "Goal",
                            systemImageName: "flag",
                            values: viewModel.allGoals
                        ) { newGoal in
                            viewModel.userGoals.insert(newGoal, at: 0)
                        }.asAny
                    }
                } header: {
                    ProfileSectionHeader(title: "Goals") {

                    }
                }

                Section {
                    if viewModel.userSupplements.isEmpty {
                        Text("No Supplements")
                    }
                    ForEach(viewModel.userSupplements, id: \.self) { supplement in
                        ProfileItemCell(title: supplement)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    viewModel.userSupplements = viewModel.userSupplements.filter({ $0 != supplement })
                                }
                            }
                    }
                    Button("Add Supplement", systemImage: "plus") {
                        presentedSheet = NewProfileItemView(
                            itemName: "Supplement",
                            systemImageName: "cross.vial",
                            values: viewModel.allSupplements
                        ) { newSupplement in
                            viewModel.userSupplements.insert(newSupplement, at: 0)
                        }.asAny
                    }
                } header: {
                    ProfileSectionHeader(title: "Supplements") {

                    }
                }

                Section {
                    if viewModel.userFacts.isEmpty {
                        Text("No Facts")
                    }
                    ForEach(viewModel.userFacts, id: \.self) { fact in
                        ProfileItemCell(title: fact)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    viewModel.userFacts = viewModel.userFacts.filter({ $0 != fact })
                                }
                            }
                    }
                    Button("Add Fact", systemImage: "plus") {
                        presentedSheet = NewProfileItemView(
                            itemName: "Fact",
                            systemImageName: "person.bust",
                            values: []
                        ) { newFact in
                            viewModel.userFacts.insert(newFact, at: 0)
                        }.asAny
                    }
                } header: {
                    ProfileSectionHeader(title: "User Facts") {

                    }
                }
            }
            .navigationTitle("Profile")
            .sheet($presentedSheet)
        }
        .task {
            try? await viewModel.loadSupplements()
            try? await viewModel.loadGoals()
        }
        .tabItem {
            Label("Profile", systemImage: "person.bust")
        }
    }
}

#Preview {
    TabView {
        ProfileView()
    }
}
