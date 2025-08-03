import Foundation
import SwiftData

extension Reminder {
  /// Adds a new side effect to the reminder
  public func addSideEffect(_ sideEffect: ReminderSideEffect) {
    if sideEffects == nil {
      sideEffects = []
    }
    sideEffects?.append(sideEffect)
    sideEffect.reminder = self
    modifiedDate = Date()
  }
  
  /// Removes a side effect from the reminder
  public func removeSideEffect(_ sideEffect: ReminderSideEffect) {
    sideEffects?.removeAll { $0.id == sideEffect.id }
    modifiedDate = Date()
  }
  
  /// Checks if the reminder has any side effects
  public var hasSideEffects: Bool {
    !(sideEffects?.isEmpty ?? true)
  }
}