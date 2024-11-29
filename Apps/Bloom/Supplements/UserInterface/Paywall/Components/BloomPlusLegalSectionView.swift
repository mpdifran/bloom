//
//  BloomPlusLegalSectionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusLegalSectionView: View {
    var body: some View {
            VStack {
                Button {

                } label: {
                    LabeledContent("Restore Purchase") {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.gray)
                    }
                    .cardContainer(fill: .background.secondary)
                }

                Button {

                } label: {
                    LabeledContent("Privacy Policy") {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(.gray)
                    }
                    .cardContainer(fill: .background.secondary)
                }

                Button {

                } label: {
                    LabeledContent("Terms of Service") {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(.gray)
                    }
                    .cardContainer(fill: .background.secondary)
                }
            }
            .buttonStyle(.plain)
            .bold()
    }
}

#Preview {
    BloomPlusLegalSectionView()
}
