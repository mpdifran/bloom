//
//  ContentView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(FocusAreaModel.all) { focusArea in
                    NavigationLink {
                        FocusAreaView(focusArea: focusArea)
                    } label: {
                        FocusAreaCell(focusArea: focusArea)
                    }
                }
            }
            .navigationTitle("Focus Areas")
        }
    }
}

#Preview {
    ContentView()
}
