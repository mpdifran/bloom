//
//  WorkoutStatView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-18.
//

import SwiftUI

struct WorkoutStatView: View {
  let stat: String

  var body: some View {
    Text(stat)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(.tint)
  }
}
