//
//  BloomPlusPaywallHeroImageView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI

struct BloomPlusPaywallHeroImageView: View {
  var body: some View {
    Image(.breakfast)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(height: 250)
  }
}

#Preview {
  BloomPlusPaywallHeroImageView()
}
