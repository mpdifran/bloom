//
//  BudImage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-23.
//

import SwiftUI

struct BudImage: View {
  let resource: ImageResource
  let dimension: CGFloat

  init(
    _ resource: ImageResource,
    dimension: CGFloat = 100
  ) {
    self.resource = resource
    self.dimension = dimension
  }

  var body: some View {
    Image(resource)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: dimension)
      .shadow(color: .white, radius: 1)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BudImage(.budCoach)
      BudImage(.budSalad)
      BudImage(.budSmoothie, dimension: 200)
    }
  }
}
