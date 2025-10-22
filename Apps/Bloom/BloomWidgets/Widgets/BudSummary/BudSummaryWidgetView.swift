//
//  BudSummaryWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import SwiftUI
import WidgetKit
internal import BloomFoundation
import BloomUI
import AppUI

struct BudSummaryWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: BudSummaryEntry

  @State private var largeWidgetContentHeight: CGFloat = 0

  var body: some View {
    Group {
      if !entry.isSubscribed {
        nonSubscriberView
      } else {
        switch family {
        case .systemMedium:
          mediumWidgetView
        case .systemLarge:
          largeWidgetView
        default:
          mediumWidgetView
        }
      }
    }
    .containerBackground(for: .widget) {
      sceneryImageView
        .zStackAlignment(.top)
    }
    .widgetURL(!entry.isSubscribed ? URL(string: "https://api.trybloom.app/paywall") : nil)
  }
}

// MARK: - Medium Widget Layout

private extension BudSummaryWidgetView {
  var mediumWidgetView: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading) {
        greetingView
        summaryView
        Spacer(minLength: 0)
      }
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 20)
          .fill(.thinMaterial)
      }
      .padding(-8)
      .padding(.trailing, 8)

      budImageView(dimension: 100)
        .scaleEffect(x: 1.5, y: 1.5)
    }
  }
}

// MARK: - Large Widget Layout

private extension BudSummaryWidgetView {
  var largeWidgetView: some View {
    VStack(alignment: .leading) {
      Spacer(minLength: 0)

      budImageView(dimension: 200)
        .scaleEffect(x: 1.25, y: 1.25)
        .offset(y: 45)
        .horizontallyCentered()

      VStack(alignment: .leading) {
        greetingView
        summaryView
      }
      .horizontalAlignment(.leading)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 20)
          .fill(.thinMaterial)
      }
      .padding(-8)
    }
  }
}

// MARK: - Non-Subscriber View

private extension BudSummaryWidgetView {

  @ViewBuilder
  var nonSubscriberView: some View {
    switch family {
    case .systemMedium:
      nonSubscriberMediumView
    case .systemLarge:
      nonSubscriberLargeView
    default:
      nonSubscriberMediumView
    }
  }

  var nonSubscriberMediumView: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading) {
        getBloomPlusTitleView
        unsubscribedSummaryView
        Spacer(minLength: 0)
      }
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 20)
          .fill(.thinMaterial)
      }
      .padding(-8)
      .padding(.trailing, 8)

      BudImage(.budCoach, dimension: 100)
        .scaleEffect(x: 1.5, y: 1.5)
    }
  }

  var nonSubscriberLargeView: some View {
    VStack(alignment: .leading) {
      Spacer(minLength: 0)

      BudImage(.budCoach, dimension: 170)
        .horizontallyCentered()

      VStack(alignment: .leading) {
        getBloomPlusTitleView
        unsubscribedSummaryView
      }
      .horizontalAlignment(.leading)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 20)
          .fill(.thinMaterial)
      }
      .padding(-8)
    }
  }
}

// MARK: - Shared Components

private extension BudSummaryWidgetView {
  var dateView: some View {
    Text(DateFormatter.weekdayFullMonthDayYear.string(from: entry.date))
      .font(.caption)
      .fontDesign(.rounded)
      .bold()
      .foregroundStyle(.secondary)
  }

  var greetingView: some View {
    Text(greetingText)
      .font(.headline)
      .bold()
      .fontDesign(.rounded)
  }

  var summaryView: some View {
    Group {
      if entry.isLoading {
        Text("Open the app to load your personalized summary.")
          .foregroundStyle(.secondary)
      } else if entry.hasError {
        Text("Whoops, looks like I made a mistake. Please open Bloom to try again.")
          .foregroundStyle(.secondary)
      } else if let summary = entry.summary {
        Text(summary)
      }
    }
    .font(.subheadline)
    .fontDesign(.rounded)
    .minimumScaleFactor(0.85)
  }

  var getBloomPlusTitleView: some View {
    Text("Get Bloom Plus Today!")
      .font(.headline)
      .bold()
      .fontDesign(.rounded)
  }

  var unsubscribedSummaryView: some View {
    Text("Get personalized insights on what’s boosting (or bumming out) your health. It’s like x-ray vision for your wellness.")
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .fontDesign(.rounded)
      .minimumScaleFactor(0.85)
  }

  func budImageView(dimension: CGFloat) -> some View {
    Group {
      if entry.hasError {
        BudImage(.budStressed, dimension: dimension)
      } else if entry.isLoading {
        BudImage(.budThinking, dimension: dimension)
      } else if let budState = entry.budState {
        budImageForState(budState, dimension: dimension)
      } else {
        BudImage(.budThinking, dimension: dimension)
      }
    }
  }

  func budImageForState(_ budState: String, dimension: CGFloat) -> some View {
    Group {
      switch budState {
      case "groggy":
        BudImage(.budGroggy, dimension: dimension)
      case "sleepy":
        BudImage(.budSleepy, dimension: dimension)
      case "eatingSalad":
        BudImage(.budSalad, dimension: dimension)
      case "holdingSmoothie":
        BudImage(.budSmoothie, dimension: dimension)
      case "holdingTrophy":
        BudImage(.budTrophy, dimension: dimension)
      case "workingOut":
        BudImage(.budWorkout, dimension: dimension)
      case "stressed":
        BudImage(.budStressed, dimension: dimension)
      case "proudCoach":
        BudImage(.budCoach, dimension: dimension)
      case "superhero":
        BudImage(.budSuperhero, dimension: dimension)
      case "running":
        BudImage(.budRunning, dimension: dimension)
      case "strengthTraining":
        BudImage(.budStrengthTraining, dimension: dimension)
      case "yoga":
        BudImage(.budYoga, dimension: dimension)
      case "bicycleRiding":
        BudImage(.budBicycle, dimension: dimension)
      default:
        BudImage(.budCoach, dimension: dimension)
      }
    }
  }

  var greetingText: String {
    let userName = entry.userName.isEmpty ? "" : ", \(entry.userName)"

    switch entry.timeMode {
    case .morning:
      return "Good Morning\(userName)!"
    case .afternoon:
      return "Good Afternoon\(userName)!"
    case .evening:
      return "Good Evening\(userName)!"
    case .night:
      return "Good Night\(userName)!"
    @unknown default:
      return "Howdy\(userName)!"
    }
  }

  @ViewBuilder
  var sceneryImageView: some View {
    let imageResource: ImageResource = {
      switch entry.timeMode {
      case .morning:
        return .morningScenery
      case .afternoon:
        return .afternoonScenery
      case .evening:
        return .eveningScenery
      case .night:
        return .nightScenery
      @unknown default:
        return .afternoonScenery
      }
    }()

    if family == .systemMedium {
      Image(imageResource)
        .resizable()
        .scaledToFill()
    } else {
      Image(imageResource)
        .resizable()
        .scaledToFit()
    }
  }
}

