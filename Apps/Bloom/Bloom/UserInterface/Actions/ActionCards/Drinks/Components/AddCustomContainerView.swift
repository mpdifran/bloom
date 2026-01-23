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

struct AddCustomContainerView: View {
  let onAdd: (ContainerSizeModel) -> Void

  @State private var name = ""
  @State private var volumeML: Double = 250
  @State private var useMetric = true

  @Environment(\.dismiss) private var dismiss

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && volumeML > 0
  }

  private var displayVolume: String {
    if useMetric {
      return "\(Int(volumeML)) mL"
    } else {
      let flOz = volumeML / 29.5735
      return String(format: "%.1f fl oz", flOz)
    }
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        VStack(spacing: 16) {
          // Name
          nameSection

          // Volume
          volumeSection

          // Preview
          previewSection
        }
        .padding(.horizontal)
      }
      .navigationTitle("Add Container")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .shelf {
        Button {
          addContainer()
        } label: {
          Text("Add Container")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(!isValid)
      }
    }
  }

  private var nameSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Name")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      TextField("My Water Bottle", text: $name)
        .textFieldStyle(.plain)
        .padding()
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(.fill)
        }
    }
  }

  private var volumeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Volume")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()

        Text(displayVolume)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.tint)
      }

      // Unit toggle
      Picker("Unit", selection: $useMetric) {
        Text("mL").tag(true)
        Text("fl oz").tag(false)
      }
      .pickerStyle(.segmented)

      // Volume slider
      if useMetric {
        Slider(value: $volumeML, in: 30...2000, step: 10)
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
      }

      // Quick presets
      quickPresets
    }
    .cardContainer()
  }

  private var quickPresets: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Quick presets")
        .font(.caption)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach([125, 250, 350, 500, 750, 1000], id: \.self) { ml in
            Button {
              volumeML = Double(ml)
            } label: {
              Text("\(ml) mL")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                  Capsule()
                    .fill(volumeML == Double(ml) ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
                }
                .foregroundStyle(volumeML == Double(ml) ? .white : .primary)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private var previewSection: some View {
    VStack(spacing: 8) {
      ContainerShapeView(
        shapeType: .glass,
        fillColor: .blue.opacity(0.3),
        strokeColor: .blue.opacity(0.6)
      )
      .frame(width: 60, height: 80)

      Text(name.isEmpty ? "My Container" : name)
        .font(.subheadline)
        .fontWeight(.medium)

      Text(displayVolume)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.fill)
    }
  }

  private func addContainer() {
    let container = ContainerSizeModel(
      name: name.trimmingCharacters(in: .whitespacesAndNewlines),
      volumeML: volumeML,
      isSystemDefault: false
    )

    onAdd(container)
    dismiss()
  }
}

#Preview {
  AddCustomContainerView { container in
    print("Added: \(container.name) - \(container.volumeML) mL")
  }
}
