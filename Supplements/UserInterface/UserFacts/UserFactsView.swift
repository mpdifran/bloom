//
//  UserFactsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-14.
//

import SwiftUI

struct UserFactsView: View {

    @ObservedObject private var viewModel = ChatViewModel.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.learnedUserFacts, id: \.self) { userFact in
                    Text(userFact)
                        .bold()
                }
            }
            .navigationTitle("User Facts")
        }
        .tabItem {
            Label("User Facts", systemImage: "person.bust")
        }
    }
}

#Preview {
    UserFactsView()
}
