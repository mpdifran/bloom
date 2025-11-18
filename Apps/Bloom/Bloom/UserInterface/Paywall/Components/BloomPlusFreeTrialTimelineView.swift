//
//  BloomPlusFreeTrialTimelineView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-18.
//

import SwiftUI
import SFSafeSymbols
import RevenueCat

struct BloomPlusFreeTrialTimelineView: View {
  
  let package: Package
  
  private var trialEndDate: Date {
    package.trialEndDate ?? Date()
  }
  
  private var trialReminderDate: Date {
    package.trialReminderDate ?? Date()
  }
  
  private var trialDurationInDays: Int {
    package.trialDurationInDays ?? 0
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GeometryReader { geometry in
        ZStack(alignment: .top) {
          timelineBar(width: geometry.size.width)

          HStack(alignment: .top, spacing: 0) {
            todayMarker
            
            Spacer()
            
            if trialDurationInDays > 2 {
              reminderMarker
              
              Spacer()
            }
            
            endMarker
          }
          .frame(width: geometry.size.width)
        }
      }
      .frame(height: 80)

      Text("We'll send you a reminder notification before your trial ends!")
        .bold()
        .font(.subheadline)
        .fontDesign(.rounded)
        .multilineTextAlignment(.leading)
    }
    .cardContainer()
  }
}

private extension BloomPlusFreeTrialTimelineView {
  
  var todayMarker: some View {
    VStack(spacing: 8) {
      ZStack {
        Circle()
          .fill(.mutedBlue)
          .frame(width: 40, height: 40)
        
        Image(systemSymbol: .checkmark)
          .foregroundStyle(.white)
          .font(.system(size: 16, weight: .bold))
      }
      
      VStack(spacing: 4) {
        Text("Today")
          .font(.caption)
          .bold()
        
        Text("Trial Starts")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  var reminderMarker: some View {
    VStack(spacing: 8) {
      ZStack {
        Circle()
          .fill(.mutedIndigo)
          .frame(width: 40, height: 40)
        
        Image(systemSymbol: .bellFill)
          .foregroundStyle(.white)
          .font(.system(size: 16))
      }
      
      VStack(spacing: 4) {
        Text(trialReminderDate.formatted(date: .abbreviated, time: .omitted))
          .font(.caption)
          .bold()
        
        Text("Trial Notification")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  var endMarker: some View {
    VStack(spacing: 8) {
      ZStack {
        Circle()
          .fill(.mutedPurple)
          .frame(width: 40, height: 40)
        
        Image(systemSymbol: .creditcardFill)
          .foregroundStyle(.white)
          .font(.system(size: 16))
      }
      
      VStack(spacing: 4) {
        Text(trialEndDate.formatted(date: .abbreviated, time: .omitted))
          .font(.caption)
          .bold()
        
        Text("Trial Ends")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  func timelineBar(width: CGFloat) -> some View {
    VStack {
      Spacer()
        .frame(height: 15)

      ZStack(alignment: .leading) {
        Rectangle()
          .fill(
            LinearGradient(
              colors: [.mutedBlue, .mutedIndigo, .mutedPurple],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: width - 80, height: 12)
      }
      
      Spacer()
    }
  }
}

#Preview {
  @Previewable @State var package: Package?

  PreviewEnvironment {
    BloomScrollView {
      if let package {
        BloomPlusFreeTrialTimelineView(package: package)
      }
    }
    .task {
      let offerings = try? await Purchases.shared.offerings()

      package = offerings?.current?.availablePackages.first(where: { package in
        package.hasFreeIntroductoryOffer
      })
    }
  }
}
