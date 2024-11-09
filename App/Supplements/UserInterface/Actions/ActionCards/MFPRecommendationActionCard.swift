//
//  MFPRecommendationActionCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import SwiftUI
import AppUI

struct MFPRecommendationActionCard: View {

    @Environment(\.openURL) private var openURL

    var body: some View {
        ActionCardView(
            title: "Log Food",
            showSaveBar: false
        ) {
            false
        } content: { _, handleSave in
            VStack(spacing: 20) {
                Image(.mfpAppIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)

                Text("Bloom doesn't yet support logging food. We recommend using another app like MyFitnessPal to log your food for now.")
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .frame(maxWidth: 300)
            .padding()
            .shelf {
                ProminentButton("View in App Store") {
                    openURL(URL(string: "https://apps.apple.com/app/id341232718")!)
                }
            }
        }
        .tint(.mutedBlue)
    }
}

#Preview {
    @Previewable @State var showSheet = true

    Button {
        showSheet.toggle()
    } label: {
        Text("Show Sheet")
    }
    .sheet(isPresented: $showSheet) {
        MFPRecommendationActionCard()
    }
}
