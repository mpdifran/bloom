//
//  ReminderDot.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-03.
//

import SwiftUI

struct ReminderDot: View {
  let color: Color

  var body: some View {
    Circle()
      .fill(color)
      .frame(square: 10)
  }
}

#Preview {
  ReminderDot(color: .mutedRed)
  ReminderDot(color: .mutedBlue)
}
