//
//  ActionCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import BloomFoundation

struct ActionCell: View {
  let imageContent: ImageContent
  let title: String
  let color: Color

  enum ImageContent {
    case resource(ImageResource)
    case system(String)
  }

  init(image: ImageResource, title: String, color: Color) {
    self.imageContent = .resource(image)
    self.title = title
    self.color = color
  }

  init(systemImage: String, title: String, color: Color) {
    self.imageContent = .system(systemImage)
    self.title = title
    self.color = color
  }

  var body: some View {
    HStack(spacing: 10) {
      imageView
        .frame(width: 24, height: 24)
      Text(title)
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
      Spacer()
    }
    .padding(.vertical, 10)
    .foregroundStyle(.white)
    .listRowBackground(
      RoundedRectangle(cornerRadius: 24)
        .fill(color)
    )
    .selectable()
  }

  @ViewBuilder
  private var imageView: some View {
    switch imageContent {
    case .resource(let resource):
      Image(resource)
        .resizable()
        .aspectRatio(contentMode: .fit)
    case .system(let name):
      Image(systemName: name)
        .font(.system(size: 18, weight: .semibold))
    }
  }
}

#Preview {
  PreviewEnvironment {
    List {
      ActionCell(
        image: .logWeightIcon,
        title: "Log Weight",
        color: .mutedIndigo
      )
    }
  }
}
