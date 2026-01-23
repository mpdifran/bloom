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

    // Monitor notifications
    public static let monitorRecoveryAttention = "monitor-recovery-attention"
    public static let monitorRecoveryAlert = "monitor-recovery-alert"
    public static let monitorStressAttention = "monitor-stress-attention"
    public static let monitorStressAlert = "monitor-stress-alert"
    public static let monitorSleepAttention = "monitor-sleep-attention"
    public static let monitorSleepAlert = "monitor-sleep-alert"

    // Workout notifications
    public static let workoutCompletion = "workout-completion"
  }

  enum CategoryID {
    public static let chatMessage = "chat-message"
    public static let goalsMessage = "goals-message"
    public static let reminders = "reminders"
    public static let trialReminder = "trial-reminder"
    public static let periodPrediction = "period-prediction"
    public static let reEngagementOnboarding = "re-engagement-onboarding"
    public static let monitorAlert = "monitor-alert"
    public static let workoutCompletion = "workout-completion"
  }

  enum ActionID {
    public static let completeReminder = "complete-reminder"
    public static let reviewSubscription = "review-subscription"
    public static let leaveFeedback = "leave-feedback"
    public static let logPeriod = "log-period"
    public static let viewMonitor = "view-monitor"
    public static let snoozeMonitor = "snooze-monitor"
    public static let viewWorkoutAnalysis = "view-workout-analysis"
  }
}
