//
//  FocusVital.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-10.
//

import Foundation
import DataContainer

struct FocusVital: Sendable, Identifiable, Hashable {
  var id: Int { hashValue }

  let vitalKind: VitalModel.Kind
  var proposedGoals: [ProposedGoal]
}
