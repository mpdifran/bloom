//
//  DrinkContainerShapes.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI

// MARK: - Shape Protocol Extension

protocol DrinkContainerShape: Shape {
  static var name: String { get }
}

// MARK: - Water Bottle Shape

struct WaterBottleShape: DrinkContainerShape {
  static let name = "Water Bottle"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Bottle proportions
    let neckWidth = width * 0.25
    let neckHeight = height * 0.12
    let shoulderHeight = height * 0.08
    let bodyWidth = width * 0.7
    let cornerRadius = width * 0.08

    // Start at top left of neck
    let neckTop = rect.minY
    let neckBottom = neckTop + neckHeight
    let shoulderBottom = neckBottom + shoulderHeight
    let bodyBottom = rect.maxY

    path.move(to: CGPoint(x: centerX - neckWidth / 2, y: neckTop))

    // Left side of neck
    path.addLine(to: CGPoint(x: centerX - neckWidth / 2, y: neckBottom))

    // Left shoulder curve
    path.addQuadCurve(
      to: CGPoint(x: centerX - bodyWidth / 2, y: shoulderBottom),
      control: CGPoint(x: centerX - bodyWidth / 2, y: neckBottom)
    )

    // Left side of body
    path.addLine(to: CGPoint(x: centerX - bodyWidth / 2, y: bodyBottom - cornerRadius))

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bodyWidth / 2 + cornerRadius, y: bodyBottom),
      control: CGPoint(x: centerX - bodyWidth / 2, y: bodyBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX + bodyWidth / 2 - cornerRadius, y: bodyBottom))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bodyWidth / 2, y: bodyBottom - cornerRadius),
      control: CGPoint(x: centerX + bodyWidth / 2, y: bodyBottom)
    )

    // Right side of body
    path.addLine(to: CGPoint(x: centerX + bodyWidth / 2, y: shoulderBottom))

    // Right shoulder curve
    path.addQuadCurve(
      to: CGPoint(x: centerX + neckWidth / 2, y: neckBottom),
      control: CGPoint(x: centerX + bodyWidth / 2, y: neckBottom)
    )

    // Right side of neck
    path.addLine(to: CGPoint(x: centerX + neckWidth / 2, y: neckTop))

    path.closeSubpath()

    return path
  }
}

// MARK: - Coffee Cup Shape

struct CoffeeCupShape: DrinkContainerShape {
  static let name = "Coffee Cup"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Cup proportions
    let topWidth = width * 0.75
    let bottomWidth = width * 0.55
    let rimHeight = height * 0.05
    let cornerRadius = width * 0.06

    let cupTop = rect.minY + rimHeight
    let cupBottom = rect.maxY

    // Rim
    path.move(to: CGPoint(x: centerX - topWidth / 2 - width * 0.03, y: rect.minY))
    path.addLine(to: CGPoint(x: centerX + topWidth / 2 + width * 0.03, y: rect.minY))
    path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: cupTop))

    // Right side (tapered)
    path.addLine(to: CGPoint(x: centerX + bottomWidth / 2, y: cupBottom - cornerRadius))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bottomWidth / 2 - cornerRadius, y: cupBottom),
      control: CGPoint(x: centerX + bottomWidth / 2, y: cupBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX - bottomWidth / 2 + cornerRadius, y: cupBottom))

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2, y: cupBottom - cornerRadius),
      control: CGPoint(x: centerX - bottomWidth / 2, y: cupBottom)
    )

    // Left side (tapered)
    path.addLine(to: CGPoint(x: centerX - topWidth / 2, y: cupTop))

    path.addLine(to: CGPoint(x: centerX - topWidth / 2 - width * 0.03, y: rect.minY))

    path.closeSubpath()

    return path
  }
}

// MARK: - Espresso Cup Shape

struct EspressoCupShape: DrinkContainerShape {
  static let name = "Espresso Cup"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Small cup proportions
    let topWidth = width * 0.65
    let bottomWidth = width * 0.45
    let cornerRadius = width * 0.08

    let cupTop = rect.minY
    let cupBottom = rect.maxY

    // Top left
    path.move(to: CGPoint(x: centerX - topWidth / 2, y: cupTop))

    // Left side (tapered)
    path.addLine(to: CGPoint(x: centerX - bottomWidth / 2, y: cupBottom - cornerRadius))

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2 + cornerRadius, y: cupBottom),
      control: CGPoint(x: centerX - bottomWidth / 2, y: cupBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX + bottomWidth / 2 - cornerRadius, y: cupBottom))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bottomWidth / 2, y: cupBottom - cornerRadius),
      control: CGPoint(x: centerX + bottomWidth / 2, y: cupBottom)
    )

    // Right side (tapered)
    path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: cupTop))

    path.closeSubpath()

    return path
  }
}

// MARK: - Tea Cup Shape

struct TeaCupShape: DrinkContainerShape {
  static let name = "Tea Cup"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Tea cup proportions (wider, more elegant)
    let topWidth = width * 0.8
    let bottomWidth = width * 0.5
    let cornerRadius = width * 0.1

    let cupTop = rect.minY
    let cupBottom = rect.maxY

    // Top left
    path.move(to: CGPoint(x: centerX - topWidth / 2, y: cupTop))

    // Left side (curved taper)
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2, y: cupBottom - cornerRadius),
      control: CGPoint(x: centerX - topWidth / 2 * 0.8, y: height * 0.6)
    )

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2 + cornerRadius, y: cupBottom),
      control: CGPoint(x: centerX - bottomWidth / 2, y: cupBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX + bottomWidth / 2 - cornerRadius, y: cupBottom))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bottomWidth / 2, y: cupBottom - cornerRadius),
      control: CGPoint(x: centerX + bottomWidth / 2, y: cupBottom)
    )

    // Right side (curved taper)
    path.addQuadCurve(
      to: CGPoint(x: centerX + topWidth / 2, y: cupTop),
      control: CGPoint(x: centerX + topWidth / 2 * 0.8, y: height * 0.6)
    )

    path.closeSubpath()

    return path
  }
}

// MARK: - Glass Shape

struct GlassShape: DrinkContainerShape {
  static let name = "Glass"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let centerX = rect.midX

    // Standard glass proportions
    let topWidth = width * 0.7
    let bottomWidth = width * 0.55
    let cornerRadius = width * 0.05

    let glassTop = rect.minY
    let glassBottom = rect.maxY

    // Top left
    path.move(to: CGPoint(x: centerX - topWidth / 2, y: glassTop))

    // Left side (slight taper)
    path.addLine(to: CGPoint(x: centerX - bottomWidth / 2, y: glassBottom - cornerRadius))

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2 + cornerRadius, y: glassBottom),
      control: CGPoint(x: centerX - bottomWidth / 2, y: glassBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX + bottomWidth / 2 - cornerRadius, y: glassBottom))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bottomWidth / 2, y: glassBottom - cornerRadius),
      control: CGPoint(x: centerX + bottomWidth / 2, y: glassBottom)
    )

    // Right side (slight taper)
    path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: glassTop))

    path.closeSubpath()

    return path
  }
}

// MARK: - Beer Glass Shape (Pint)

struct BeerGlassShape: DrinkContainerShape {
  static let name = "Beer Glass"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Pint glass proportions (wider at top)
    let topWidth = width * 0.8
    let middleWidth = width * 0.6
    let bottomWidth = width * 0.55
    let bulgeHeight = height * 0.3
    let cornerRadius = width * 0.06

    let glassTop = rect.minY
    let bulgeY = rect.maxY - bulgeHeight
    let glassBottom = rect.maxY

    // Top left
    path.move(to: CGPoint(x: centerX - topWidth / 2, y: glassTop))

    // Left side upper (tapered in)
    path.addLine(to: CGPoint(x: centerX - middleWidth / 2, y: bulgeY))

    // Left side lower (slight bulge out then in)
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2, y: glassBottom - cornerRadius),
      control: CGPoint(x: centerX - middleWidth / 2 - width * 0.02, y: bulgeY + bulgeHeight * 0.5)
    )

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bottomWidth / 2 + cornerRadius, y: glassBottom),
      control: CGPoint(x: centerX - bottomWidth / 2, y: glassBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX + bottomWidth / 2 - cornerRadius, y: glassBottom))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bottomWidth / 2, y: glassBottom - cornerRadius),
      control: CGPoint(x: centerX + bottomWidth / 2, y: glassBottom)
    )

    // Right side lower (slight bulge)
    path.addQuadCurve(
      to: CGPoint(x: centerX + middleWidth / 2, y: bulgeY),
      control: CGPoint(x: centerX + middleWidth / 2 + width * 0.02, y: bulgeY + bulgeHeight * 0.5)
    )

    // Right side upper (tapered out)
    path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: glassTop))

    path.closeSubpath()

    return path
  }
}

// MARK: - Wine Glass Shape

struct WineGlassShape: DrinkContainerShape {
  static let name = "Wine Glass"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Wine glass proportions
    let bowlTopWidth = width * 0.75
    let bowlBottomWidth = width * 0.15
    let bowlHeight = height * 0.55
    let stemHeight = height * 0.30
    let baseWidth = width * 0.5
    let baseHeight = height * 0.08

    let bowlTop = rect.minY
    let bowlBottom = bowlTop + bowlHeight
    let stemBottom = bowlBottom + stemHeight
    let baseBottom = rect.maxY

    // Bowl - top left
    path.move(to: CGPoint(x: centerX - bowlTopWidth / 2, y: bowlTop))

    // Bowl left side (curved)
    path.addQuadCurve(
      to: CGPoint(x: centerX - bowlBottomWidth / 2, y: bowlBottom),
      control: CGPoint(x: centerX - bowlTopWidth / 2 * 1.1, y: bowlTop + bowlHeight * 0.6)
    )

    // Stem left
    path.addLine(to: CGPoint(x: centerX - bowlBottomWidth / 2, y: stemBottom))

    // Base left curve
    path.addQuadCurve(
      to: CGPoint(x: centerX - baseWidth / 2, y: baseBottom - baseHeight * 0.3),
      control: CGPoint(x: centerX - baseWidth / 2, y: stemBottom)
    )

    // Base bottom left
    path.addLine(to: CGPoint(x: centerX - baseWidth / 2, y: baseBottom))

    // Base bottom
    path.addLine(to: CGPoint(x: centerX + baseWidth / 2, y: baseBottom))

    // Base bottom right
    path.addLine(to: CGPoint(x: centerX + baseWidth / 2, y: baseBottom - baseHeight * 0.3))

    // Base right curve
    path.addQuadCurve(
      to: CGPoint(x: centerX + bowlBottomWidth / 2, y: stemBottom),
      control: CGPoint(x: centerX + baseWidth / 2, y: stemBottom)
    )

    // Stem right
    path.addLine(to: CGPoint(x: centerX + bowlBottomWidth / 2, y: bowlBottom))

    // Bowl right side (curved)
    path.addQuadCurve(
      to: CGPoint(x: centerX + bowlTopWidth / 2, y: bowlTop),
      control: CGPoint(x: centerX + bowlTopWidth / 2 * 1.1, y: bowlTop + bowlHeight * 0.6)
    )

    path.closeSubpath()

    return path
  }
}

// MARK: - Shaker Shape

struct ShakerShape: DrinkContainerShape {
  static let name = "Shaker"

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let centerX = rect.midX

    // Shaker bottle proportions
    let capWidth = width * 0.4
    let capHeight = height * 0.08
    let neckWidth = width * 0.35
    let neckHeight = height * 0.05
    let bodyWidth = width * 0.7
    let cornerRadius = width * 0.08

    let capTop = rect.minY
    let capBottom = capTop + capHeight
    let neckBottom = capBottom + neckHeight
    let bodyBottom = rect.maxY

    // Cap
    path.move(to: CGPoint(x: centerX - capWidth / 2, y: capTop))
    path.addLine(to: CGPoint(x: centerX - capWidth / 2, y: capBottom))

    // Neck left
    path.addLine(to: CGPoint(x: centerX - neckWidth / 2, y: capBottom))
    path.addLine(to: CGPoint(x: centerX - neckWidth / 2, y: neckBottom))

    // Shoulder left
    path.addQuadCurve(
      to: CGPoint(x: centerX - bodyWidth / 2, y: neckBottom + height * 0.08),
      control: CGPoint(x: centerX - bodyWidth / 2, y: neckBottom)
    )

    // Body left
    path.addLine(to: CGPoint(x: centerX - bodyWidth / 2, y: bodyBottom - cornerRadius))

    // Bottom left corner
    path.addQuadCurve(
      to: CGPoint(x: centerX - bodyWidth / 2 + cornerRadius, y: bodyBottom),
      control: CGPoint(x: centerX - bodyWidth / 2, y: bodyBottom)
    )

    // Bottom
    path.addLine(to: CGPoint(x: centerX + bodyWidth / 2 - cornerRadius, y: bodyBottom))

    // Bottom right corner
    path.addQuadCurve(
      to: CGPoint(x: centerX + bodyWidth / 2, y: bodyBottom - cornerRadius),
      control: CGPoint(x: centerX + bodyWidth / 2, y: bodyBottom)
    )

    // Body right
    path.addLine(to: CGPoint(x: centerX + bodyWidth / 2, y: neckBottom + height * 0.08))

    // Shoulder right
    path.addQuadCurve(
      to: CGPoint(x: centerX + neckWidth / 2, y: neckBottom),
      control: CGPoint(x: centerX + bodyWidth / 2, y: neckBottom)
    )

    // Neck right
    path.addLine(to: CGPoint(x: centerX + neckWidth / 2, y: capBottom))
    path.addLine(to: CGPoint(x: centerX + capWidth / 2, y: capBottom))

    // Cap right
    path.addLine(to: CGPoint(x: centerX + capWidth / 2, y: capTop))

    path.closeSubpath()

    return path
  }
}

// MARK: - Shape View

struct ContainerShapeView: View {
  let shapeType: ContainerShapeType
  let fillColor: Color
  let strokeColor: Color
  let strokeWidth: CGFloat

  init(
    shapeType: ContainerShapeType,
    fillColor: Color = .clear,
    strokeColor: Color = .secondary,
    strokeWidth: CGFloat = 2
  ) {
    self.shapeType = shapeType
    self.fillColor = fillColor
    self.strokeColor = strokeColor
    self.strokeWidth = strokeWidth
  }

  var body: some View {
    switch shapeType {
    case .waterBottle:
      WaterBottleShape()
        .fill(fillColor)
        .overlay { WaterBottleShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .coffeeCup:
      CoffeeCupShape()
        .fill(fillColor)
        .overlay { CoffeeCupShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .espressoCup:
      EspressoCupShape()
        .fill(fillColor)
        .overlay { EspressoCupShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .teaCup:
      TeaCupShape()
        .fill(fillColor)
        .overlay { TeaCupShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .glass:
      GlassShape()
        .fill(fillColor)
        .overlay { GlassShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .beerGlass:
      BeerGlassShape()
        .fill(fillColor)
        .overlay { BeerGlassShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .wineGlass:
      WineGlassShape()
        .fill(fillColor)
        .overlay { WineGlassShape().stroke(strokeColor, lineWidth: strokeWidth) }
    case .shaker:
      ShakerShape()
        .fill(fillColor)
        .overlay { ShakerShape().stroke(strokeColor, lineWidth: strokeWidth) }
    }
  }
}

// MARK: - Preview

#Preview("Container Shapes") {
  ScrollView {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
      ForEach(ContainerShapeType.allCases, id: \.self) { shapeType in
        VStack {
          ContainerShapeView(
            shapeType: shapeType,
            fillColor: .blue.opacity(0.3),
            strokeColor: .blue
          )
          .frame(width: 80, height: 120)

          Text(shapeType.rawValue)
            .font(.caption)
        }
      }
    }
    .padding()
  }
}
