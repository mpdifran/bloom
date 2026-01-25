//
//  BudImage.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2025-06-23.
//

import SwiftUI
import AppUI
import WidgetKit

public struct BudImage: View {
  let resource: ImageResource
  let dimension: CGFloat

  public init(
    _ resource: ImageResource,
    dimension: CGFloat = 100
  ) {
    self.resource = resource
    self.dimension = dimension
  }

  public var body: some View {
    Image(resource)
      .resizable()
      .widgetAccentedRenderingMode(.fullColor)
      .aspectRatio(contentMode: .fit)
      .frame(height: dimension)
      .shadow(color: .white, radius: 1)
  }
}

#Preview {
  ScrollView {
    VStack {
      Group {
        BudImage(.budCoach)
        BudImage(.budYoga)
        BudImage(.budBicycle)
        BudImage(.budSalad)
        BudImage(.budGroggy)
        BudImage(.budSleepy)
        BudImage(.budTrophy)
        BudImage(.budRunning)
        BudImage(.budWorkout)
        BudImage(.budSmoothie)
        BudImage(.budStressed)
        BudImage(.budThinking)
        BudImage(.budSuperhero)
        BudImage(.budStrengthTraining)
      }
      .border(.green)
    }
    .horizontallyCentered()
    .padding()
  }
}
