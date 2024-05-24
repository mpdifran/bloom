//
//  PinView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI

struct PinView: View {

    @ObservedObject private var viewModel = PinViewModel.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.pins, id: \.self) { pin in
                    ActivityCell(activityModel: pin)
                }
            }
            .navigationTitle("Pins")
        }
        .tabItem {
            Label("Pins", systemImage: "pin.fill")
        }
    }
}

#Preview {
    PinView()
}
