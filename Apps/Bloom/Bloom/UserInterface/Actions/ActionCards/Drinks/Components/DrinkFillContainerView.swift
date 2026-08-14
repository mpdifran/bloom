//
//  DrinkFillContainerView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import CoreHealth

struct DrinkFillContainerView: View {
  let drink: DrinkType
  let container: ContainerSizeModel
  @Binding var fillPercentage: Double

  @State private var hapticTrigger = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        // Container outline (empty)
        containerFill(Color.secondary.opacity(0.1))

        // Liquid fill
        containerFill(drink.liquidColor.gradient)
          .frame(height: geometry.size.height * fillPercentage)
          .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: fillPercentage)

        // Container stroke overlay
        containerStroke()

        // Percentage indicator
        VStack {
          Spacer()

          Text(fillPercentage, format: .percent.precision(.fractionLength(0)))
            .font(.title2)
            .fontWeight(.bold)
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .offset(y: -geometry.size.height * fillPercentage / 2)
            .opacity(fillPercentage > 0.15 ? 1 : 0)

          Spacer()
        }
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            let newPercentage = 1.0 - (value.location.y / geometry.size.height)
            let clampedPercentage = min(1.0, max(0.05, newPercentage))

            // Trigger haptic on 10% increments
            let newTrigger = Int(clampedPercentage * 10)
            if newTrigger != hapticTrigger {
              hapticTrigger = newTrigger
            }

            fillPercentage = clampedPercentage
          }
      )
      .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
  }

  @ViewBuilder
  private func containerFill<S: ShapeStyle>(_ style: S) -> some View {
    switch drink.containerShapeType {
    case .waterBottle:
      WaterBottleShape().fill(style)
    case .coffeeCup:
      CoffeeCupShape().fill(style)
    case .espressoCup:
      EspressoCupShape().fill(style)
    case .teaCup:
      TeaCupShape().fill(style)
    case .glass:
      GlassShape().fill(style)
    case .beerGlass:
      BeerGlassShape().fill(style)
    case .wineGlass:
      WineGlassShape().fill(style)
    case .shaker:
      ShakerShape().fill(style)
    case .can:
      CanShape().fill(style)
    case .mug:
      MugShape().fill(style)
    case .tumbler:
      TumblerShape().fill(style)
    case .shotGlass:
      ShotGlassShape().fill(style)
    @unknown default:
      GlassShape().fill(style)
    }
  }

  @ViewBuilder
  private func containerStroke() -> some View {
    switch drink.containerShapeType {
    case .waterBottle:
      WaterBottleShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .coffeeCup:
      CoffeeCupShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .espressoCup:
      EspressoCupShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .teaCup:
      TeaCupShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .glass:
      GlassShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .beerGlass:
      BeerGlassShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .wineGlass:
      WineGlassShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .shaker:
      ShakerShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .can:
      CanShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .mug:
      MugShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .tumbler:
      TumblerShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    case .shotGlass:
      ShotGlassShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    @unknown default:
      GlassShape().stroke(Color.secondary.opacity(0.3), lineWidth: 3)
    }
  }
}

#Preview {
  @Previewable @State var fillPercentage = 0.5

  VStack {
    DrinkFillContainerView(
      drink: DrinkType.defaultDrinks.first!,
      container: ContainerSizeModel.defaults[2],
      fillPercentage: $fillPercentage
    )
    .frame(width: 150, height: 250)
    .padding()

    Text(fillPercentage, format: .percent.precision(.fractionLength(0)))
      .font(.title)

    Slider(value: $fillPercentage, in: 0.05...1.0)
      .padding()
  }
}
