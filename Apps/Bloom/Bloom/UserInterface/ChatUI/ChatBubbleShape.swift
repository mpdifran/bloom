//
//  ChatBubbleShape.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-05-15.
//

import SwiftUI

extension ChatBubbleShape {
    private static let bubbleRadius: CGFloat = 20
    private static let tailExposure: CGFloat = 3
    private static let tailCornerRadius: CGFloat = 1.5

    public enum TailPosition: Sendable {
        case none, leading, trailing
    }
}

public struct ChatBubbleShape: Shape {

    let tailPosition: TailPosition

    public func path(in rect: CGRect) -> Path {
        let effectiveRadius = min(Self.bubbleRadius, rect.width / 2)

        let topLeftCorner = CGPoint(x: effectiveRadius, y: effectiveRadius)
        let topRightCorner = CGPoint(x: rect.width - effectiveRadius, y: effectiveRadius)
        let bottomLeftCorner = CGPoint(x: effectiveRadius, y: rect.height - effectiveRadius)
        let bottomRightCorner = CGPoint(x: rect.width - effectiveRadius, y: rect.height - effectiveRadius)


        var path = Path()

        // Top Left
        path.move(to: CGPoint(x: effectiveRadius, y: 0))
        path.addLine(to: CGPoint(x: rect.width - effectiveRadius, y: 0))

        // Top Right
        path.addArc(center: topRightCorner, radius: effectiveRadius, startAngle: Angle.degrees(-90), endAngle: Angle.degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - effectiveRadius))

        // Bottom Right
        if tailPosition == .trailing {

            path.addLine(to: CGPoint(x: rect.width, y: rect.height + Self.tailExposure))
            path.addArc(center: CGPoint(x: rect.width - Self.tailCornerRadius, y: rect.height + Self.tailExposure),
                        radius: Self.tailCornerRadius,
                        startAngle: Angle.degrees(0),
                        endAngle: Angle.degrees(135),
                        clockwise: false)

            path.addArc(center: bottomRightCorner, radius: effectiveRadius, startAngle: Angle.degrees(63), endAngle: Angle.degrees(90), clockwise: false)

        } else {
            path.addArc(center: bottomRightCorner, radius: effectiveRadius, startAngle: Angle.degrees(0), endAngle: Angle.degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: effectiveRadius, y: rect.height))
        }

        // Bottom Left
        if tailPosition == .leading {
            path.addArc(center: bottomLeftCorner, radius: effectiveRadius, startAngle: Angle.degrees(90), endAngle: Angle.degrees(120), clockwise: false)

            path.addArc(center: CGPoint(x: Self.tailCornerRadius, y: rect.height + Self.tailExposure),
                        radius: Self.tailCornerRadius,
                        startAngle: Angle.degrees(60),
                        endAngle: Angle.degrees(180),
                        clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: rect.height + Self.tailExposure))

        } else {
            path.addArc(center: bottomLeftCorner, radius: effectiveRadius, startAngle: Angle.degrees(90), endAngle: Angle.degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: effectiveRadius))
        }

        // Top Left
        path.addArc(center: topLeftCorner, radius: effectiveRadius, startAngle: Angle.degrees(180), endAngle: Angle.degrees(270), clockwise: false)

        path.closeSubpath()
        return path
    }
}

struct ChatBubbleShape_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Leading")
                .padding()
                .background(
                    ChatBubbleShape(tailPosition: .leading)
                    .stroke(lineWidth: 1)
                    .fill(Color.blue)
                )
            Text("Trailing")
                .padding()
                .background(
                    ChatBubbleShape(tailPosition: .trailing)
                    .stroke(lineWidth: 1)
                    .fill(Color.blue)
                )

            Text("None")
                .padding()
                .background(
                    ChatBubbleShape(tailPosition: .none)
                    .stroke(lineWidth: 1)
                    .fill(Color.blue)
                )

            ZStack {
//                ChatBubble(position: .trailing,
//                           showTail: true,
//                           foregroundColor: .white,
//                           backgroundColor: .green) {
//                    Text("Hello World")
//                }

                HStack {
                    Spacer()
                    Text("Hello World")
                        .padding(10)
                        .background(
                            ChatBubbleShape(tailPosition: .trailing)
                                .fill(Color.blue)
                        )
                        .padding(.trailing)
                        .opacity(0.2)

                }
            }
        }
    }
}
