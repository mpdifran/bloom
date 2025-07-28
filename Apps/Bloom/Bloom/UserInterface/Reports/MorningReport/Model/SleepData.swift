//
//  SleepData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation

struct SleepData: SendableNetworkModel {
  let sleepSessions: [SleepSession]
}

struct SleepSession: SendableNetworkModel {
  let startDate: Date
  let endDate: Date
  let totalSleepTime: String
  let sleepScore: Int?
  let deepSleep: String?
  let coreSleep: String?
  let remSleep: String?
  let awakeTime: String?
  let averageHeartRate: String?
  let averageRespiratoryRate: String?
  let averageSoundLevel: String?
  let wristTemperature: String?
}