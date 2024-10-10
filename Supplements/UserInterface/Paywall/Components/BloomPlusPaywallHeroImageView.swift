//
//  BloomPlusPaywallHeroImageView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusPaywallHeroImageView: View {
    var body: some View {
        image
            .background {
                image
                    .scaleEffect(1.5)
                    .blur(radius: 60)
            }
    }
}

private extension BloomPlusPaywallHeroImageView {

    var image: some View {
        Image(.womanInMirror)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    BloomPlusPaywallHeroImageView()
}
