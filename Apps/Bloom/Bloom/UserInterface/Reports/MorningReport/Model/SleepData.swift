//
//  SleepData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import CoreNetwork

struct SleepData: SendableNetworkModel {
  let sleepSession: SleepSession
}

struct SleepSession: SendableNetworkModel {
  let bedtimeLocal: String
  let wakeupTimeLocal: String
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
  let bedtimeTrend: String?
  let wakeupTimeTrend: String?
  let sleepEfficiency: String?
  let sleepEfficiencyTrend: String?
}