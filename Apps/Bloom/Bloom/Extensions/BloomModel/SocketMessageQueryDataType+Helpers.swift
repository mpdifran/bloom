//
//  SocketMessageQueryDataType+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-14.
//

import BloomModel

extension SocketMessage.QueryDataType {

  var name: String {
    switch self {
    case .foodLogs: "food logs"
    case .nutrition: "nutrition"
    case .goals: "goals"
    case .activityLevel: "activity level"
    case .bodyWeight: "body weight"
    case .bowelMovements: "bowel movements"
    case .heart: "heart health"
    case .menstruation: "cycle tracking"
    case .sleep: "sleep"
    case .stress: "stress"
    case .workouts: "workouts"
    case .targetHeartRateZoneMinutes: "target heart rate zones"
    }
  }
}
