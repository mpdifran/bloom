//
//  MealRecordCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI
import DataContainer

private extension CGFloat {
  static let imageHeight: CGFloat = 160
}

struct MealRecordCell: View {
  let mealRecord: MealRecordDTO

  var body: some View {
    VStack {
      Group {
        if let imageData = mealRecord.imageData, let image = UIImage(data: imageData) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: .imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
          RoundedRectangle(cornerRadius: 18)
            .fill(.fill)
            .frame(height: .imageHeight)
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, 8)

      HStack {
        VStack(alignment: .leading) {
          Text(mealRecord.name)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)

          Text("23g Protein • 7g Fat • 42g Carbs")
            .font(.caption)
            .foregroundStyle(.secondary)
            .bold()
            .fontDesign(.rounded)
        }
        .lineLimit(2)

        Spacer()

        Text("607 cals")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .bold()
          .fontDesign(.rounded)

        Button {

        } label: {
          Image(systemSymbol: .plusCircleFill)
            .foregroundStyle(.tint, .tint.tertiary)
            .font(.largeTitle)
        }
      }
      .padding(.horizontal)
    }
    .padding(.bottom)
    .cardContainer(includePadding: false)
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        MealRecordCell(
          mealRecord: MealRecord.Preview.crackersAndCheese.asDTO()
        )
        MealRecordCell(
          mealRecord: MealRecord.Preview.crackersAndCheeseNoImage.asDTO()
        )
      }
      .horizontallyCentered()
      .padding()
    }
    .groupedBackground()
  }
}
