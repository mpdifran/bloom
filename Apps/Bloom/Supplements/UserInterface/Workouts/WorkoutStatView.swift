//
//  WorkoutStatView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-18.
//

import SwiftUI

struct WorkoutStatView: View {
  let stat: String
  let label: String?

  init(stat: String, label: String? = nil) {
    self.stat = stat
    self.label = label
  }

  var body: some View {
    HStack {
      if let label {
        Text(label)
          .font(.caption)
      }
      Text(stat)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
    }
  }
}

#Preview {
  VStack(alignment: .trailing) {
    WorkoutStatView(stat: "642 Cal")
    WorkoutStatView(stat: "642 Cal", label: "Active")
  }
  .padding()
}
