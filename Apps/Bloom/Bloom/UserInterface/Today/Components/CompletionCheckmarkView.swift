//
//  CompletionCheckmarkView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import SFSafeSymbols
import SwiftUI

extension CompletionCheckmarkView {
  enum State {
    case unmetGoal
    case metGoal
    case exceededGoal
  }
}

struct CompletionCheckmarkView: View {
  let state: State
  let colorize: Bool

  init(
    state: State,
    colorize: Bool = false
  ) {
    self.state = state
    self.colorize = colorize
  }

  var body: some View {
    Group {
      switch state {
      case .unmetGoal:
        Image(systemSymbol: .circle)
          .foregroundStyle(colorize ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
      case .metGoal:
        if colorize {
          Image(systemSymbol: .checkmarkCircleFill)
            .foregroundStyle(.white, .tint)
        } else {
          Image(systemSymbol: .checkmarkCircleFill)
            .foregroundStyle(.tint, .white)
        }

      case .exceededGoal:
        if colorize {
          Image(systemSymbol: .exclamationmarkCircle)
            .foregroundStyle(.white)
            .background {
              Circle()
                .fill(.tint)
            }
        } else {
          Image(systemSymbol: .exclamationmarkCircle)
            .foregroundStyle(.tint, .white)
            .background {
              Circle()
                .fill(.white.secondary)
            }
        }
      }
    }
    .font(.title)
    .contentTransition(.symbolEffect)
    .animation(.bouncy, value: state)
  }
}

#Preview {
  ScrollView {
    VStack {
      CompletionCheckmarkView(state: .unmetGoal)
      CompletionCheckmarkView(state: .metGoal)
      CompletionCheckmarkView(state: .exceededGoal)

      CompletionCheckmarkView(state: .unmetGoal, colorize: true)
      CompletionCheckmarkView(state: .metGoal, colorize: true)
      CompletionCheckmarkView(state: .exceededGoal, colorize: true)
    }
    .horizontallyCentered()
  }
  .groupedBackground()
  .tint(.mutedGreen)
}
