//
//  UserProfilePhotoView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI

struct UserProfilePhotoView: View {
  let dimension: CGFloat

  init(dimension: CGFloat = 140) {
    self.dimension = dimension
  }

  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    Circle()
      .fill(.tint.secondary)
      .frame(square: dimension)
      .overlay {
        Text(healthManager.name.prefix(1))
          .font(.system(size: dimension / 1.4, weight: .heavy))
          .bold()
          .fontDesign(.rounded)
          .minimumScaleFactor(0.05)
          .padding(dimension / 10)
          .foregroundStyle(.tint)
          .contentTransition(.numericText())
      }
      .animation(.default, value: healthManager.name)
  }
}

#Preview {
  UserProfilePhotoView()
  UserProfilePhotoView(dimension: 80)
  UserProfilePhotoView(dimension: 30)
}
