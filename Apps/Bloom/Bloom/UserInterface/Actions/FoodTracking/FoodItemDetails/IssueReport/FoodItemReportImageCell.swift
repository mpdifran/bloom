//
//  FoodItemReportImageCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-04.
//

import SwiftUI
import AppUI

struct FoodItemReportImageCell: View {
  let systemImage: String
  let title: String
  @Binding var image: UIImage?

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack {
      Image(systemName: systemImage)
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
          systemImage: "vial.viewfinder",
          title: "Packaging",
          image: $image
        )
        FoodItemReportImageCell(
          systemImage: "text.viewfinder",
          title: "Nutrition Label",
          image: $image
        )
      }

      HStack {
        FoodItemReportImageCell(
          systemImage: "vial.viewfinder",
          title: "Packaging",
          image: .constant(.woman)
        )
        FoodItemReportImageCell(
          systemImage: "text.viewfinder",
          title: "Nutrition Label",
          image: .constant(.woman)
        )
      }
    }
    .padding()
  }
  .groupedBackground()
}
