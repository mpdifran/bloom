//
//  DisplayAppIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-10.
//

import SwiftUI

struct DisplayAppIcon: View {
  var body: some View {
    Image(.bloomAppIcon)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .shadow(color: .gray, radius: 0.5)
  }
}

#Preview {
  DisplayAppIcon()
    .padding()
}
