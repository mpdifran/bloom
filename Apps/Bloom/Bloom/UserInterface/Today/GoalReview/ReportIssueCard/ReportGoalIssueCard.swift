//
//  ReportGoalIssueCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI
import AppFoundations
import TelemetryDeck

extension ReportGoalIssueCard {
  enum GoalIssue: String, CaseIterable, Identifiable {
    var id: Self { self }

    case goalsWereRelevant
    case noGoalsRecommended
    case goalTooLowOrTooHigh
    case goalsAreNotRelevant
    case goalsAreStale
    case goalWantingToKeepIsRemoved
    case descriptionDoesNotMakeSense

    var name: String {
      switch self {
      case .goalsWereRelevant:
        "Goal(s) are relevant"
      case .noGoalsRecommended:
        "No goals were recommended"
      case .goalTooLowOrTooHigh:
        "Goal(s) are too low or too high"
      case .goalsAreNotRelevant:
        "Goal(s) are not relevant"
      case .goalsAreStale:
        "Goal(s) are always the same"
      case .goalWantingToKeepIsRemoved:
        "Goal(s) I want to keep are removed"
      case .descriptionDoesNotMakeSense:
        "Goal description does not make sense"
      }
    }
  }
}

struct ReportGoalIssueCard: View {

  @State private var comment = ""
  @State private var selectedIssues = Set<GoalIssue>()
  @State private var selectIssueToggle = false
  @State private var didSubmitFeedback = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    CardView {
      VStack {
        ScrollView {
          LargeTitleActionCard("Give Goal Feedback") {
            Text("Select all that apply.")
              .bold()
              .fontDesign(.rounded)

            ForEach(GoalIssue.allCases) { issue in
              ReportGoalIssueCell(
                title: issue.name,
                isSelected: selectedIssues.contains(issue)
              )
              .sensoryFeedback(.selection, trigger: selectIssueToggle)
              .onTapGesture {
                selectedIssues.toggleMembership(issue)
                selectIssueToggle.toggle()
              }
            }

            SectionTitleView("Comment (Optional)")
              .padding(.horizontal)

            TextEditor(text: $comment)
              .submitLabel(.done)
              .frame(height: 80)
              .cardContainer()
          }
        }

        submitButton
          .padding()
      }
    }
    .animation(.default, value: selectedIssues)
    .tint(.mutedYellow)
  }
}

private extension ReportGoalIssueCard {

  var submitButton: some View {
    Button {
      guard !didSubmitFeedback else { return }
      Task {
        await submitFeedback()
      }
    } label: {
      Group {
        if didSubmitFeedback {
          Label("Submitted", systemSymbol: .checkmark)
        } else {
          Label("Submit", systemSymbol: .heartFill)
        }
      }
      .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .sensoryFeedback(.success, trigger: didSubmitFeedback)
  }

  func submitFeedback() async {
    var parameters = [String: String]()
    for issue in GoalIssue.allCases {
      parameters[issue.rawValue] = selectedIssues.contains(issue) ? "Present" : "Not Present"
    }

    let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedComment.isNotEmpty {
      parameters["comment"] = trimmedComment
    }

    TelemetryDeck.signal(
      "AI Goal Setting Feedback",
      parameters: parameters
    )

    didSubmitFeedback = true

    await Delay(1000)

    dismiss()
  }
}

#Preview {
  PreviewSheetPresent {
    ReportGoalIssueCard()
  }
}
