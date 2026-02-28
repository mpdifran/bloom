//
//  AchievementStore.swift
//  Bloom
//
//  Created by Claude on 2026-02-28.
//

import UIKit

struct AchievementRecord: Codable, Identifiable {
  let id: UUID
  let dateAchieved: Date
  let kindIdentifier: String
  let title: String
  let shareMessage: String
  let imageFileName: String
}

@MainActor
@Observable
final class AchievementStore {

  static let shared = AchievementStore()

  private(set) var records: [AchievementRecord] = []

  private let defaults = UserDefaults.standard
  private static let recordsKey = "achievements.records"

  private init() {
    loadRecords()
  }
}

// MARK: - Public API

extension AchievementStore {

  func save(kind: CelebrationKind, image: UIImage) {
    let identifier = kind.achievementIdentifier

    guard !records.contains(where: { $0.kindIdentifier == identifier }) else { return }

    let id = UUID()
    let fileName = "\(id.uuidString).jpg"

    guard saveImageToDisk(image, fileName: fileName) else { return }

    let record = AchievementRecord(
      id: id,
      dateAchieved: Date(),
      kindIdentifier: identifier,
      title: kind.title,
      shareMessage: kind.shareMessage(),
      imageFileName: fileName
    )

    records.insert(record, at: 0)
    persistRecords()
  }

  func imageURL(for record: AchievementRecord) -> URL? {
    let url = Self.achievementsDirectory.appendingPathComponent(record.imageFileName)
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    return url
  }

  func resetAll() {
    // Delete image files
    let fileManager = FileManager.default
    for record in records {
      let url = Self.achievementsDirectory.appendingPathComponent(record.imageFileName)
      try? fileManager.removeItem(at: url)
    }

    // Clear records
    records.removeAll()
    persistRecords()

    // Reset celebration UserDefaults keys so milestones can re-trigger
    resetCelebrationKeys()
  }
}

// MARK: - Persistence

private extension AchievementStore {

  static var achievementsDirectory: URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Achievements", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  func loadRecords() {
    guard let data = defaults.data(forKey: Self.recordsKey),
          let decoded = try? JSONDecoder().decode([AchievementRecord].self, from: data)
    else { return }
    records = decoded.sorted { $0.dateAchieved > $1.dateAchieved }
  }

  func persistRecords() {
    guard let data = try? JSONEncoder().encode(records) else { return }
    defaults.set(data, forKey: Self.recordsKey)
  }

  func saveImageToDisk(_ image: UIImage, fileName: String) -> Bool {
    guard let jpegData = image.jpegData(compressionQuality: 0.85) else { return false }
    let url = Self.achievementsDirectory.appendingPathComponent(fileName)
    do {
      try jpegData.write(to: url)
      return true
    } catch {
      return false
    }
  }

  func resetCelebrationKeys() {
    let defaults = UserDefaults.standard

    // Bio age
    defaults.removeObject(forKey: "celebrations.bioAge.lastCelebratedThreshold")

    // Zone minutes
    defaults.removeObject(forKey: "celebrations.zoneMinutes.150")
    defaults.removeObject(forKey: "celebrations.zoneMinutes.300")

    // Perfect sleep
    defaults.removeObject(forKey: "celebrations.perfectSleep")

    // Goal streaks - remove all keys matching the pattern
    let allKeys = defaults.dictionaryRepresentation().keys
    for key in allKeys where key.hasPrefix("celebrations.goalStreak.") {
      defaults.removeObject(forKey: key)
    }
  }
}
