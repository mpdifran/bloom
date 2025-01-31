//
//  FoodItemIssueReportView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-30.
//

import SwiftUI
import BloomModel

struct FoodItemIssueReportView: View {
  let foodItem: FoodItem

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {

        }
        .padding()
      }
      .navigationTitle("Report an Issue")
    }
  }
}

#Preview {
  FoodItemIssueReportView(foodItem: .Preview.ritzCrackers)
}
