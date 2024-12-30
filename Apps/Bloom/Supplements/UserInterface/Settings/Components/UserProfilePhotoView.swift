//
//  UserProfilePhotoView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI

struct UserProfilePhotoView: View {
  let name: String

  var body: some View {
    Circle()
      .fill(.fill)
      .frame(square: 140)
      .overlay {
        Text(name.prefix(1))
          .font(.system(size: 100))
          .bold()
          .fontDesign(.rounded)
          .minimumScaleFactor(0.1)
          .padding()
      }
  }
}

#Preview {
  UserProfilePhotoView(name: "Mark")
  UserProfilePhotoView(name: "Katie")
  UserProfilePhotoView(name: "Tori")
}
