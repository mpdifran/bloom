//
//  TodayTabView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import BloomFoundation
import SFSafeSymbols
import AppUI

struct TodayTabView: View {
  private let provider = TodayProvider.shared

  var body: some View {
    Group {
      if provider.reminders.isNotEmpty {
        contentView
      } else {
        emptyStateView
      }
    }
    .navigationTitle("Reminders")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.bouncy, value: provider.reminders)
    .onAppear {
      provider.loadFromApplicationContext()
    }
  }

  private var contentView: some View {
    ScrollViewReader { proxy in
      List {
        ForEach(provider.reminders.reversed()) { reminder in
          WatchReminderCell(reminder: reminder)
        }
      }
      .listStyle(.carousel)
      .onAppear {
        if let lastReminder = provider.reminders.reversed().last {
          proxy.scrollTo(lastReminder.id, anchor: .center)
        }
      }
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 8) {
      Image(systemSymbol: .checkmarkCircleFill)
        .font(.largeTitle)
        .foregroundStyle(.white, .mutedRed)

      Text("No Reminders")
        .font(.headline)
        .fontDesign(.rounded)

      Text("You have no reminders for today.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      TodayTabView()
    }
  }
}
