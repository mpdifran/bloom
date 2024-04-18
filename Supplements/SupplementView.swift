//
//  SupplementView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-18.
//

import SwiftUI
import AppUI

struct SupplementView: View {
    let supplement: SupplementModel

    var body: some View {
        List {
            Section {
                Text(supplement.whatIsIt)
            } header: {
                VStack {
                    Image(supplement.image)
                        .resizable()
                        .scaledToFit()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, -20)
                        .padding(.bottom)

                    Text("What is it?")
                        .zStackAlignment(.leading)
                }
            }
            Section("Benefits") {
                Text(supplement.benefits)
            }
            Section("Drawbacks") {
                Text(supplement.drawbacks)
            }
            Section("Dosage Information") {
                Text(supplement.dosageInformation)
            }
        }
        .navigationTitle(supplement.name)
        .shelf {
            ProminentButton("Buy • $29.99", systemImage: "cart") {

            }
        }
    }
}

#Preview {
    NavigationStack {
        SupplementView(supplement: .capsaicinSupplement)
    }
}
