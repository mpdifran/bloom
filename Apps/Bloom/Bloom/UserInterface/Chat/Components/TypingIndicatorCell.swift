//
//  TypingIndicatorCell.swift
//  AirChat
//
//  Created by Mark DiFranco on 2022-02-07.
//

import SwiftUI
import BloomUI

private enum Constants {
  static let dotSize: CGFloat = 9
}

public struct TypingIndicatorCell: View {

  let isDirect: Bool

  public init(isDirect: Bool) {
    self.isDirect = isDirect
  }

  @State private var dot1Opacity: CGFloat = 0.3
  @State private var dot2Opacity: CGFloat = 0.3
  @State private var dot3Opacity: CGFloat = 0.3

  public var body: some View {
    //    ChatBubble(
    //      position: .leading,
    //      showTail: true,
    //      shouldFill: !isDirect,
    //      foregroundStyle: Color(uiColor: .label),
    //      backgroundStyle: .background.secondary
    //    ) {
    tripleDotAnimation
      .horizontalAlignment(.leading)
      .padding()
    //    }
  }
}

extension TypingIndicatorCell {

  var tripleDotAnimation: some View {
    HStack(spacing: 4) {
      Circle()
        .frame(width: Constants.dotSize, height: Constants.dotSize)
        .opacity(dot1Opacity)
        .animation(.with(delay: 0),
                   value: dot1Opacity)
      Circle()
        .frame(width: Constants.dotSize, height: Constants.dotSize)
        .opacity(dot2Opacity)
        .animation(.with(delay: 0.32),
                   value: dot2Opacity)
      Circle()
        .frame(width: Constants.dotSize, height: Constants.dotSize)
        .opacity(dot3Opacity)
        .animation(.with(delay: 0.64),
                   value: dot3Opacity)
    }
    .foregroundColor(Color(uiColor: .secondaryLabel))
    .frame(height: 20)
    .onAppear {
      dot1Opacity = 0.9
      dot2Opacity = 0.9
      dot3Opacity = 0.9
    }
  }
}

extension Animation {

  static func with(delay: CGFloat) -> Animation {
    Animation
      .easeIn(duration: 0.69)
      .repeatForever(autoreverses: true)
      .delay(delay)
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        TypingIndicatorCell(isDirect: false)
        TypingIndicatorCell(isDirect: true)
      }
    }
    .groupedBackground()
  }
}
