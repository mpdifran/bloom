//
//  BudImage.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2025-06-23.
//

import SwiftUI

public struct BudImage: View {
  let resource: ImageResource
  let dimension: CGFloat

  public init(
    _ resource: ImageResource,
    dimension: CGFloat = 100
  ) {
    self.resource = resource
    self.dimension = dimension
  }

  public var body: some View {
    Image(resource)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: dimension)
      .shadow(color: .white, radius: 1)
  }
}
