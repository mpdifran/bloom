//
//  BloomPlusHeaderView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusHeaderView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text("Bloom")
                    .padding(4)
                Text("Plus")
                    .fontDesign(.monospaced)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.mutedBlue)
                    }
            }
            .bold()
            .font(.caption)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.regularMaterial)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .gray)
                    .font(.title)
            }
            .frame(square: 44)
        }
    }
}

#Preview {
    BloomPlusHeaderView()
}
