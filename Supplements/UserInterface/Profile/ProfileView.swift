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
                } footer: {
                    Text("Tell Bloom more details about yourself.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
