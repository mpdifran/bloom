//
//  AICameraRoundedImageView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-10.
//

import SwiftUI

struct AICameraRoundedImageView: View {
  let image: UIImage

  var body: some View {
    GeometryReader { geometry in
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(square: geometry.size.width)
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 30))
  }
}

#Preview {
  AICameraRoundedImageView(image: .breakfast)
}
