//
//  ActionCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import BloomFoundation

struct ActionCell: View {
  let image: ImageResource
  let title: String

  var body: some View {
    HStack(spacing: 10) {
      Image(image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 24, height: 24)
      Text(title)
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
      Spacer()
    }
    .padding(.vertical, 10)
    .selectable()
  }
}
