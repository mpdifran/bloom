//
//  CreateWorkoutPlanView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI
import BloomModel
import AppUI
import SFSafeSymbols
import CoreHealth

struct CreateWorkoutPlanView: View {
  @State private var viewModel = CreateWorkoutPlanViewModel()

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        descriptionSection
        durationSection
        equipmentSection
      }
      .navigationTitle("Create A Plan")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .shelf {
        AsyncButton {
          try await viewModel.createPlan()
        } label: {
          Label("Create Plan", systemSymbol: .sparkles)
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .tint(.blue)
        .disabled(viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .alert(error: $viewModel.error)
    .fullScreenCover(isPresented: $viewModel.showingPreview) {
      if let plan = viewModel.generatedPlan {
        NavigationStack {
          CreateWorkoutPlanPreviewView(workoutPlan: plan) {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Views

private extension CreateWorkoutPlanView {

  var durationSection: some View {
    VStack {
      SectionTitleView("Duration")
        .padding(.horizontal)

      HStack {
        ForEach(WorkoutDuration.allCases, id: \.self) { duration in
          durationCell(duration)
        }
      }
    }
    .sensoryFeedback(.impact, trigger: viewModel.selectedDuration)
  }

  func durationCell(_ duration: WorkoutDuration) -> some View {
    let isSelected = viewModel.selectedDuration == duration

    return VStack(spacing: 4) {
      Text(duration.title)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(isSelected ? .white : .primary)

      Text(duration.subtitle)
        .font(.caption)
        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
    }
    .frame(maxWidth: .infinity)
    .cardContainer(fill: isSelected ? AnyShapeStyle(.blue) : AnyShapeStyle(.background))
    .onTapGesture {
      withAnimation(.easeInOut(duration: 0.2)) {
        viewModel.selectedDuration = duration
      }
    }
  }

  var equipmentSection: some View {
    VStack {
      HStack(alignment: .firstTextBaseline) {
        SectionTitleView("Equipment")
          .padding(.horizontal)

        Spacer()

        Button {
          viewModel.toggleSelectAll()
        } label: {
          Text(viewModel.allVisibleSelected ? "Deselect All" : "Select All")
            .font(.subheadline)
            .bold()
        }

        if viewModel.showShowAllButton {
          Button {
            viewModel.toggleShowAll()
          } label: {
            Text(viewModel.showAllEquipment ? "Show Owned" : "Show All")
              .font(.subheadline)
              .bold()
          }
        }
      }

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        ForEach(viewModel.visibleEquipment, id: \.self) { equipment in
          equipmentCell(equipment)
        }
      }
    }
    .sensoryFeedback(.impact, trigger: viewModel.selectedEquipment)
  }

  func equipmentCell(_ equipment: SocketMessage.WorkoutPlan.Equipment) -> some View {
    let isSelected = viewModel.selectedEquipment.contains(equipment.rawValue)

    return VStack(spacing: 8) {
      Image(equipment.image)
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))

      Text(equipment.name)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(isSelected ? .white : .primary)
    }
    .frame(maxWidth: .infinity)
    .cardContainer(fill: isSelected ? AnyShapeStyle(.blue) : AnyShapeStyle(.background))
    .onTapGesture {
      viewModel.toggleEquipment(equipment)
    }
  }

  var descriptionSection: some View {
    VStack {
      SectionTitleView("Describe Your Workout", includeTopPadding: false)
        .padding(.horizontal)

      TextEditor(text: $viewModel.description)
        .frame(minHeight: 120)
        .scrollContentBackground(.hidden)
        .overlay(alignment: .topLeading) {
          if viewModel.description.isEmpty {
            Text("e.g. A 30 minute upper body strength workout focusing on chest and back.")
              .foregroundStyle(.tertiary)
              .padding(.top, 8)
              .padding(.leading, 4)
              .allowsHitTesting(false)
          }
        }
        .cardContainer()
    }
  }
}

#Preview {
  PreviewEnvironment {
    CreateWorkoutPlanView()
  }
}
