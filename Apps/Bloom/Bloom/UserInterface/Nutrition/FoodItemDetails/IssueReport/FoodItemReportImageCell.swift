//
//  FoodItemReportImageCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-04.
//

import SFSafeSymbols
import SwiftUI
import AppUI

struct FoodItemReportImageCell: View {
  let symbol: SFSymbol
  let title: String
  @Binding var image: UIImage?

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack {
      Image(systemSymbol: symbol)
        .font(.title3)
        .bold()
      Text(title)
        .font(.caption)
        .bold()
    }
    .foregroundStyle(.tint)
    .horizontallyCentered()
    .frame(minHeight: 90)
    .padding()
    .overlay {
      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      }
    }
    .cardContainer(includePadding: false)
    .selectable()
    .sheet($presentedSheet)
    .onTapGesture {
      presentedSheet = CameraView(
        capturedImage: $image,
        instructions: "Position the item within the frame",
        aspectRatio: 0.8
      ).asAny
    }
  }
}

#Preview {
  @Previewable @State var image: UIImage?

  ScrollView {
    VStack {
      HStack {
        FoodItemReportImageCell(
          symbol: .vialViewfinder,
          title: "Packaging",
          image: $image
        )
        FoodItemReportImageCell(
          symbol: .textViewfinder,
          title: "Nutrition Label",
          image: $image
        )
      }

      HStack {
        FoodItemReportImageCell(
          symbol: .vialViewfinder,
          title: "Packaging",
          image: .constant(.budLounging)
        )
        FoodItemReportImageCell(
          symbol: .textViewfinder,
          title: "Nutrition Label",
          image: .constant(.budLounging)
        )
      }
    }
    .padding()
  }
  .groupedBackground()
}
