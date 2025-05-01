//
//  UserProfilePhotoView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct UserProfilePhotoView: View {
  let dimension: CGFloat
  let canEdit: Bool
  let showBorder: Bool

  init(
    dimension: CGFloat = 140,
    canEdit: Bool = false,
    showBorder: Bool = true
  ) {
    self.dimension = dimension
    self.canEdit = canEdit
    self.showBorder = showBorder
  }

  @ObservedObject private var userController = UserController.shared
  @ObservedObject private var healthManager = HealthManager.shared

  @State private var presentedSheet: AnyView?

  var body: some View {
    Group {
      if canEdit {
        ImagePicker(
          image: $userController.profilePhoto,
          presentedSheet: $presentedSheet
        ) {
          photoContent
            .overlay {
              Image(systemSymbol: .pencil)
                .foregroundStyle(.tint)
                .padding(8)
                .background {
                  Circle()
                    .fill(.tint.secondary)
                    .overlay {
                      Circle()
                        .stroke(.fill)
                    }
                    .background {
                      Circle()
                        .fill(.background)
                    }
                }
                .zStackAlignment(.bottomTrailing)
                .padding(4)
            }
        }
      } else {
        photoContent
      }
    }
    .animation(.default, value: userController.profilePhoto)
    .sheet($presentedSheet)
  }
}

private extension UserProfilePhotoView {

  @ViewBuilder
  var photoContent: some View {
    if let image = userController.profilePhoto {
      Circle()
        .fill(.tint)
        .frame(square: dimension)
        .overlay {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(square: imageDimension)
            .clipShape(Circle())
        }
    } else {
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

  var imageDimension: CGFloat {
    if showBorder {
      let maxDimension = dimension - 4
      let proportionalDimension = dimension * 0.9

      return min(maxDimension, proportionalDimension)
    } else {
      return dimension
    }
  }
}

#Preview {
  UserProfilePhotoView()
  UserProfilePhotoView(canEdit: true)
  UserProfilePhotoView(dimension: 80)
  UserProfilePhotoView(dimension: 30)
}
