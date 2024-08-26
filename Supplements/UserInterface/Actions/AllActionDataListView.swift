//
//  AllActionDataListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI

struct AllActionDataListView: View {
    var body: some View {
        ScrollView {
            VStack {
                NavigationLink {
                    BowelMovementAllDataView()
                } label: {
                    BowelMovementAllDataCell()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("All Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AllActionDataListView()
    }
}
