//
//  BloomPlusLaurelView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-18.
//

import SwiftUI

struct BloomPlusLaurelView: View {
    let title: String

    var body: some View {
        HStack {
            Image(systemName: "laurel.leading")
                .font(.largeTitle)

            Text(title)
                .multilineTextAlignment(.center)
                .bold()

            Image(systemName: "laurel.trailing")
                .font(.largeTitle)
        }
        .bold()
        .frame(maxWidth: 160)
    }
}

#Preview {
    BloomPlusLaurelView(title: "Best Health App 2025")
}
