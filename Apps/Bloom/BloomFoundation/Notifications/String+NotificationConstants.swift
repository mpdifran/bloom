//
//  String+NotificationConstants.swift
//  BloomFoundation
//
//  Created by Assistant on 2025-06-05.
//

import Foundation

public extension String {
  enum NotificationID {
    public static let goodMorning = "good-morning"
    public static let goodEvening = "good-evening"
    public static let reviewFocusAreas = "review-focus-areas"
    public static let trialReminder = "trial-reminder"
    public static let periodPredictionNear = "period-prediction-near"
    public static let periodPredictionImminent = "period-prediction-imminent"
    public static let periodPredictionLate = "period-prediction-late"
    public static let reEngagement = "re-engagement"
  }

  enum CategoryID {
    public static let chatMessage = "chat-message"
    public static let goalsMessage = "goals-message"
    public static let reminders = "reminders"
    public static let trialReminder = "trial-reminder"
    public static let periodPrediction = "period-prediction"
    public static let reEngagementOnboarding = "re-engagement-onboarding"
  }

  enum ActionID {
    public static let completeReminder = "complete-reminder"
    public static let reviewSubscription = "review-subscription"
    public static let leaveFeedback = "leave-feedback"
    public static let logPeriod = "log-period"
  }
}
