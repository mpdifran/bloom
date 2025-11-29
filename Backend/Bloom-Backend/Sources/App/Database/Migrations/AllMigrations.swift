//
//  AllMigrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Fluent

let allMigrations: [Migration] = [
  EnablePgTrgmMigration(),
  FoodItemRecord.Create(),
  FoodItemRecord.AddNutrients(),
  FoodItemRecord.FixNutritionFieldTypes(),
  FoodItemRecord.AddSourceProperty(),
  FoodItemRecord.AddNeedsAIProcessingState(),
  FoodItemRecord.AddNeedsMoreInfoAndNotes(),
  User.Create(),
  UserToken.Create(),
  User.AddUserDetails(),
  AdminUser.Create(),
  AdminUserToken.Create(),
  AdminUserToken.FixUserIDColumnName(),
  FoodItemIssueReport.Create(),
  FoodItemIssueReport.FixRelations(),
  FoodItemIssueReport.MakeNameOptional(),
  User.AddAppUserID(),
  FoodItemIssueReport.RemoveBarcodePropoerty(),
  FoodItemAccuracyReport.Create(),
  User.AddAssistantAndThreadIDs(),
  AssistantRecord.Create(),
  User.RemoveAssistantID(),
  FoodItemIssueReport.AddFoodItemRecordIndex(),
  User.RenameThreadID(),
  User.AddHealthGoalSetterThreadID(),
  User.AddAppVersion(),
  User.AddAPNSDeviceToken(),
  AssistantRecord.AddAssistantSpecHash(),
  ChatMessageIssueReport.Create(),
  ChatMessageIssueReport.AddState(),
  ChatMessageIssueReport.AddAppVersion(),
  FoodItemRecord.ConvertCountryEnumToString(),
  User.AddMorningNotificationTime(),
  User.AddConsentTracking(),
  FoodItemRecord.AddDuplicateFields(),
  FoodItemDuplicate.Create(),
  FoodItemRecord.AddLogCount(),
  FoodItemRecord.AddStateIndex(),
  FoodItemRecord.AddSearchTextColumn(),
  UserConsentRecord.Create(),
  UserConsentRecord.AddUserIDIndex(),
  UserConsentRecord.MigrateExistingConsent(),
  User.RemoveOldConsentFields(),
]
