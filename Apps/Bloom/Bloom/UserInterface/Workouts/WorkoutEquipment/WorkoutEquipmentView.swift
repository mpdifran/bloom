//
//  WorkoutEquipmentView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-26.
//

import SwiftUI
import BloomModel
import AppUI
import SFSafeSymbols
import CoreHealth

struct WorkoutEquipmentView: View {
  @ObservedObject private var healthManager = HealthManager.shared
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        ForEach(SocketMessage.WorkoutPlan.Equipment.allCases, id: \.self) { equipment in
          equipmentCell(equipment)
        }
      }
      .sensoryFeedback(.impact, trigger: healthManager.selectedWorkoutEquipment)
      .navigationTitle("Workout Equipment")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
      }
      .shelf {
        Button {
          toggleAllEquipment()
        } label: {
          Text(selectAllButtonTitle)
            .bold()
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
    }
  }
}

// MARK: - Views

private extension WorkoutEquipmentView {
  
  func equipmentCell(_ equipment: SocketMessage.WorkoutPlan.Equipment) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(equipment.name)
          .font(.headline)
          .foregroundStyle(.primary)
        
        Text(equipmentDescription(for: equipment))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      if healthManager.selectedWorkoutEquipment.contains(equipment.rawValue) {
        Image(systemSymbol: .checkmark)
          .font(.body.weight(.semibold))
          .foregroundStyle(.tint)
      }
    }
    .cardContainer()
    .onTapGesture {
      toggleEquipment(equipment)
    }
  }
}

// MARK: - Actions

private extension WorkoutEquipmentView {
  
  func toggleEquipment(_ equipment: SocketMessage.WorkoutPlan.Equipment) {
    withAnimation(.easeInOut(duration: 0.2)) {
      if healthManager.selectedWorkoutEquipment.contains(equipment.rawValue) {
        healthManager.selectedWorkoutEquipment.remove(equipment.rawValue)
      } else {
        healthManager.selectedWorkoutEquipment.insert(equipment.rawValue)
      }
    }
  }
  
  func toggleAllEquipment() {
    withAnimation(.easeInOut(duration: 0.2)) {
      if healthManager.selectedWorkoutEquipment.count == SocketMessage.WorkoutPlan.Equipment.allCases.count {
        // All selected, so deselect all
        healthManager.selectedWorkoutEquipment.removeAll()
      } else {
        // Not all selected, so select all
        healthManager.selectedWorkoutEquipment = Set(SocketMessage.WorkoutPlan.Equipment.allCases.map(\.rawValue))
      }
    }
  }
}

// MARK: - Helpers

private extension WorkoutEquipmentView {
  
  var selectAllButtonTitle: String {
    if healthManager.selectedWorkoutEquipment.count == SocketMessage.WorkoutPlan.Equipment.allCases.count {
      return "Deselect All"
    } else {
      return "Select All"
    }
  }
  
  func equipmentDescription(for equipment: SocketMessage.WorkoutPlan.Equipment) -> String {
    switch equipment {
    case .dumbbells:
      return "Free weights for strength training"
    case .barbell:
      return "Long bar with weights for compound exercises"
    case .kettlebell:
      return "Cast iron weight for dynamic movements"
    case .batBell:
      return "Weighted bat for rotational exercises"
    case .chinUpBar:
      return "Pull-up bar for upper body exercises"
    case .treadmill:
      return "Running machine for cardio workouts"
    case .stationaryBike:
      return "Indoor cycling machine"
    case .bike:
      return "Outdoor or indoor bicycle"
    case .elliptical:
      return "Low-impact cardio machine"
    case .rowingMachine:
      return "Full-body cardio and strength machine"
    case .skiMachine:
      return "Nordic skiing simulator"
    case .yogaMat:
      return "Cushioned mat for floor exercises"
    case .resistanceBand:
      return "Elastic bands for resistance training"
    case .weightedVest:
      return "Wearable weight for added resistance"
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    WorkoutEquipmentView()
  }
}
