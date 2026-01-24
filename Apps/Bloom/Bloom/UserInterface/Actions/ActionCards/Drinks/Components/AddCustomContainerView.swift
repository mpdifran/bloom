//
//  AddCustomContainerView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomUI
import AppUI
import CoreHealth

struct AddCustomContainerView: View {
  let onAdd: (ContainerSizeModel) -> Void

  init(onAdd: @escaping (ContainerSizeModel) -> Void) {
    self.onAdd = onAdd
  }

  @State private var name = ""
  @State private var volumeML: Double = 250
  @State private var volumeText = ""
  @State private var selectedShape: ContainerShapeType = .glass

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isVolumeFieldFocused: Bool

  private var unitPreferences = HealthUnitPreferences.shared

  private var isMetric: Bool {
    unitPreferences.liquidVolumeUnit == .literUnit(with: .milli)
  }

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && volumeML > 0
  }

  private var displayVolume: String {
    if isMetric {
      return "\(Int(volumeML)) mL"
    } else {
      let flOz = volumeML / 29.5735
      return String(format: "%.1f %@", flOz, unitPreferences.liquidVolumeUnit.sensibleUnitString)
    }
  }

  private var displayValueOnly: String {
    if isMetric {
      return "\(Int(volumeML))"
    } else {
      let flOz = volumeML / 29.5735
      return String(format: "%.1f", flOz)
    }
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        previewSection
          .padding(.bottom)
          .padding(.bottom)

        nameSection
        volumeSection
        shapeSection
      }
      .navigationTitle("Add Container")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .safeAreaInset(edge: .bottom) {
        Button {
          addContainer()
        } label: {
          Text("Add Container")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(!isValid)
        .padding()
      }
    }
  }

  private var nameSection: some View {
    TextField("My Water Bottle", text: $name)
      .textFieldStyle(.plain)
      .cardContainer()
  }

  private var volumeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        Text("Volume")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()

        HStack(spacing: 4) {
          TextField("0", text: $volumeText)
            .textFieldStyle(.roundedBorder)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            .frame(minWidth: 100)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .fixedSize()
            .focused($isVolumeFieldFocused)
            .onChange(of: volumeText) {
              updateVolumeFromText()
            }

          Text(unitPreferences.liquidVolumeUnit.sensibleUnitString)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
        }
      }

      // Volume slider
      if isMetric {
        Slider(value: $volumeML, in: 30...2000, step: 10)
          .onChange(of: volumeML) {
            if !isVolumeFieldFocused {
              volumeText = displayValueOnly
            }
          }
      } else {
        // Convert slider to fl oz scale
        Slider(
          value: Binding(
            get: { volumeML / 29.5735 },
            set: { volumeML = $0 * 29.5735 }
          ),
          in: 1...64,
          step: 0.5
        )
        .onChange(of: volumeML) {
          if !isVolumeFieldFocused {
            volumeText = displayValueOnly
          }
        }
      }
    }
    .cardContainer()
    .onAppear {
      volumeText = displayValueOnly
    }
  }

  private func updateVolumeFromText() {
    guard let value = Double(volumeText.replacingOccurrences(of: ",", with: ".")) else { return }

    if isMetric {
      volumeML = max(1, min(value, 5000))
    } else {
      // Convert fl oz to mL
      volumeML = max(1, min(value * 29.5735, 5000))
    }
  }

  private var previewSection: some View {
    VStack(spacing: 8) {
      ContainerShapeView(
        shapeType: selectedShape,
        fillColor: .blue.opacity(0.3),
        strokeColor: .blue.opacity(0.6)
      )
      .frame(width: 60, height: 80)

      Text(name.isEmpty ? "My Container" : name)
        .font(.subheadline)
        .fontWeight(.medium)
        .contentTransition(.numericText())

      Text(displayVolume)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer()
    .animation(.default, value: name)
    .animation(.default, value: selectedShape)
  }

  private var shapeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Shape")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 12)],
        spacing: 12
      ) {
        ForEach(ContainerShapeType.allCases, id: \.self) { shape in
          ShapePickerCell(
            shape: shape,
            isSelected: selectedShape == shape
          )
          .onTapGesture {
            selectedShape = shape
          }
        }
      }
    }
    .cardContainer()
    .animation(.default, value: selectedShape)
    .sensoryFeedback(.selection, trigger: selectedShape)
  }

  private func addContainer() {
    let container = ContainerSizeModel(
      name: name.trimmingCharacters(in: .whitespacesAndNewlines),
      volumeML: volumeML,
      shapeType: selectedShape,
      isSystemDefault: false
    )

    onAdd(container)
    dismiss()
  }
}

// MARK: - Shape Picker Cell

private struct ShapePickerCell: View {
  let shape: ContainerShapeType
  let isSelected: Bool

  var body: some View {
    VStack(spacing: 6) {
      ContainerShapeView(
        shapeType: shape,
        fillColor: isSelected ? .blue.opacity(0.3) : .secondary.opacity(0.1),
        strokeColor: isSelected ? .blue : .secondary.opacity(0.5),
        strokeWidth: isSelected ? 2 : 1.5
      )
      .frame(width: 35, height: 45)

      Text(shape.displayName)
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
    }
    .contentShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  PreviewEnvironment {
    AddCustomContainerView { container in
      print("Added: \(container.name) - \(container.volumeML) mL")
    }
  }
}
