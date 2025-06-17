//
//  BloomPlusPaywallHeroImageView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusPaywallHeroImageView: View {
  var body: some View {
    ZStack {
      Color.clear
        .background {
          image
            .clipped()
            .background {
              image
                .scaleEffect(1.5)
                .blur(radius: 60)
            }
            .zStackAlignment(.top)
        }
    }
  }
}

private extension BloomPlusPaywallHeroImageView {

  var image: some View {
    Image(.breakfast)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(height: 250)
  }
}

#Preview {
  BloomPlusPaywallHeroImageView()
}
