//
//  BloomPlusLegalSectionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusLegalSectionView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                Button("Restore Purchase", systemImage: "arrow.clockwise") {

                }

                Button("Privacy Policy", systemImage: "hand.raised") {

                }

                Button("Terms of Service", systemImage: "list.clipboard") {

                }
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .bold()

            Spacer()
        }
    }
}

#Preview {
    BloomPlusLegalSectionView()
}
