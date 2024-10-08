//
//  BloomPlusPaywallHeroImageView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusPaywallHeroImageView: View {
    var body: some View {
        Image(.womanInMirror)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    BloomPlusPaywallHeroImageView()
}
