//
//  AchievementsView.swift
//  Bloom
//
//  Created by Claude on 2026-02-28.
//

import SwiftUI
import AppUI
import BloomUI
import TelemetryDeck

struct AchievementsView: View {

  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var sharingRecord: AchievementRecord?

  @Environment(\.dismiss) private var dismiss

  private let store = AchievementStore.shared

  private let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16)
  ]

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        if store.records.isEmpty {
          emptyState
        } else {
          achievementsGrid
        }

        achievementCategories
          .padding(.top, 8)
      }
      .navigationTitle("Achievements")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }

        if store.records.isNotEmpty {
          ToolbarItem(placement: .primaryAction) {
            Button("Reset", role: .destructive) {
              confirmationDialogDetails = ConfirmationDialogDetails(
                title: "Reset Achievements",
                message: "Are you sure you want to reset all achievements? This will clear your achievement history and allow you to earn them again.",
                buttons: [
                  ConfirmationDialogDetails.Button(title: "Reset All", role: .destructive) {
                    store.resetAll()
                  },
                  ConfirmationDialogDetails.Button(title: "Cancel", role: .cancel) { }
                ]
              )
            }
          }
        }
      }
      .confirmationDialog($confirmationDialogDetails)
      .sheet(isPresented: Binding(
        get: { sharingRecord != nil },
        set: { if !$0 { sharingRecord = nil } }
      )) {
        if let record = sharingRecord, let url = store.imageURL(for: record) {
          ShareSheet(items: [url, record.shareMessage]) { completed in
            guard completed else { return }
            TelemetryDeck.signal("Share Achievement", parameters: ["kind": record.kindIdentifier])
          }
        }
      }
    }
  }
}

// MARK: - Achievements Grid

private extension AchievementsView {

  var achievementsGrid: some View {
    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(store.records) { record in
        achievementCell(record)
      }
    }
    .padding(.horizontal)
  }

  func achievementCell(_ record: AchievementRecord) -> some View {
    Button {
      sharingRecord = record
    } label: {
      VStack(spacing: 8) {
        if let url = store.imageURL(for: record) {
          AsyncImage(url: url) { image in
            image
              .resizable()
              .scaledToFit()
          } placeholder: {
            RoundedRectangle(cornerRadius: 12)
              .fill(.quaternary)
              .aspectRatio(0.7, contentMode: .fit)
          }
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        Text(record.dateAchieved.formatted(.dateTime.month(.abbreviated).day().year()))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Empty State

private extension AchievementsView {

  var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "trophy")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("No Achievements Yet")
        .font(.title2)
        .bold()
        .fontDesign(.rounded)

      Text("Achievements are earned by reaching health milestones. Keep using Bloom and they'll start appearing here!")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 40)
  }
}

// MARK: - Achievement Categories

private extension AchievementsView {

  var achievementCategories: some View {
    VStack(spacing: 12) {
      Text("How to Earn Achievements")
        .font(.headline)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)

      categoryCell(
        icon: "heart.circle",
        title: "Biological Age",
        description: "Lower your biological age below your actual age."
      )

      categoryCell(
        icon: "flame",
        title: "Goal Streaks",
        description: "Hit your daily habit goals consistently."
      )

      categoryCell(
        icon: "bolt.heart",
        title: "Zone Minutes",
        description: "Earn 150+ zone minutes in a week through exercise."
      )

      categoryCell(
        icon: "moon.zzz",
        title: "Perfect Sleep",
        description: "Score a perfect 100 on your sleep score."
      )
    }
  }

  func categoryCell(icon: String, title: String, description: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .fontDesign(.rounded)

        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()
    }
    .cardContainer()
    .padding(.horizontal)
  }
}

// MARK: - Preview

#Preview("Empty") {
  PreviewEnvironment {
    AchievementsView()
  }
}

#Preview("With Achievements") {
  PreviewSheetPresent {
    AchievementsView()
  }
}
