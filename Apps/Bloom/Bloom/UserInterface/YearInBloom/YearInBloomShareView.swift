//
//  YearInBloomShareView.swift
//  Bloom
//
//  Created by Claude on 2025-12-19.
//

import SwiftUI

struct YearInBloomShareView<Content: View>: View {
  let appIcon: ImageResource
  let content: Content

  init(appIcon: ImageResource, @ViewBuilder content: () -> Content) {
    self.appIcon = appIcon
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      content
        .background {
          Rectangle()
            .fill(.background)
        }

      // Small watermark at bottom
      HStack(spacing: 4) {
        Image(appIcon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 20, height: 20)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        Text("Year In Bloom")
          .bold()
          .font(.caption)
          .fontDesign(.rounded)
          .foregroundStyle(.white)
      }
      .padding(.vertical, 8)
    }
    .background(.black)
  }
}

#Preview {
  PreviewEnvironment {
    YearInBloomShareView(appIcon: .bloomDisplayAppIconBlue) {
      Text("Hello World")
    }
  }
}
