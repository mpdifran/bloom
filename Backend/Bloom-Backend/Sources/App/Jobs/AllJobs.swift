//
//  AllJobs.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-19.
//

import Vapor
import VaporCron

@MainActor let allJobs: [any VaporCronSchedulable.Type] = [
  FoodItemRecordAccuracyJob.self,
]
