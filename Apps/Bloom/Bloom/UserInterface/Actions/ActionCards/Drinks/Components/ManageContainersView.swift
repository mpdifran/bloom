//
//  ManageContainersView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomUI
import AppUI

struct ManageContainersView: View {

  @State private var containers: [ContainerSizeModel] = ContainerSizeModel.loadAll()
  @State private var editingContainer: ContainerSizeModel?
  @State private var showingAddSheet = false
  @State private var showingResetAlert = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        VStack(spacing: 12) {
          ForEach(containers) { container in
            containerRow(container)
          }

          addButton
        }
        .padding(.horizontal)
      }
      .navigationTitle("Manage Containers")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }

        ToolbarItem(placement: .primaryAction) {
          Menu {
            Button("Reset to Defaults", systemImage: "arrow.counterclockwise") {
              showingResetAlert = true
            }
          } label: {
            Image(systemSymbol: .ellipsisCircle)
          }
        }
      }
      .sheet(item: $editingContainer) { container in
        EditContainerView(container: container) { updated in
          if let index = containers.firstIndex(where: { $0.id == updated.id }) {
            containers[index] = updated
            saveContainers()
          }
          editingContainer = nil
        }
      }
      .sheet(isPresented: $showingAddSheet) {
        AddCustomContainerView { container in
          containers.append(container)
          saveContainers()
        }
      }
      .alert("Reset to Defaults?", isPresented: $showingResetAlert) {
        Button("Cancel", role: .cancel) { }
        Button("Reset", role: .destructive) {
          containers = ContainerSizeModel.defaults
          saveContainers()
        }
      } message: {
        Text("This will remove all custom containers and restore the default container sizes.")
      }
    }
  }

  private func containerRow(_ container: ContainerSizeModel) -> some View {
    HStack(spacing: 12) {
      // Mini container shape
      ContainerShapeView(
        shapeType: .glass,
        fillColor: .blue.opacity(0.2),
        strokeColor: .blue.opacity(0.5),
        strokeWidth: 1
      )
      .frame(width: 30, height: 40)

      // Info
      VStack(alignment: .leading, spacing: 2) {
        Text(container.name)
          .font(.subheadline)
          .fontWeight(.medium)

        Text(container.displayValue())
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Edit button
      Button {
        editingContainer = container
      } label: {
        Image(systemSymbol: .pencil)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)

      // Delete button
      Button {
        deleteContainer(container)
      } label: {
        Image(systemSymbol: .trash)
          .foregroundStyle(.red)
      }
      .buttonStyle(.plain)
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.fill)
    }
  }

  private var addButton: some View {
    Button {
      showingAddSheet = true
    } label: {
      HStack {
        Image(systemSymbol: .plusCircle)
        Text("Add Container")
      }
      .font(.subheadline)
      .fontWeight(.medium)
      .foregroundStyle(.tint)
      .frame(maxWidth: .infinity)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 12)
          .fill(.fill)
          .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
          .foregroundStyle(.tint.opacity(0.3))
      }
    }
    .buttonStyle(.plain)
  }

  private func deleteContainer(_ container: ContainerSizeModel) {
    containers.removeAll { $0.id == container.id }
    saveContainers()
  }

  private func saveContainers() {
    ContainerSizeModel.save(containers)
  }
}

// MARK: - Edit Container View

struct EditContainerView: View {
  let container: ContainerSizeModel
  let onSave: (ContainerSizeModel) -> Void

  @State private var name: String
  @State private var volumeML: Double
  @State private var useMetric = true

  @Environment(\.dismiss) private var dismiss

  init(container: ContainerSizeModel, onSave: @escaping (ContainerSizeModel) -> Void) {
    self.container = container
    self.onSave = onSave
    _name = State(initialValue: container.name)
    _volumeML = State(initialValue: container.volumeML)
  }

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
          VStack(alignment: .leading, spacing: 8) {
            Text("Name")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            TextField("Container Name", text: $name)
              .textFieldStyle(.plain)
              .padding()
              .background {
                RoundedRectangle(cornerRadius: 12)
                  .fill(.fill)
              }
          }

          // Volume
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

            Picker("Unit", selection: $useMetric) {
              Text("mL").tag(true)
              Text("fl oz").tag(false)
            }
            .pickerStyle(.segmented)

            if useMetric {
              Slider(value: $volumeML, in: 30...2000, step: 10)
            } else {
              Slider(
                value: Binding(
                  get: { volumeML / 29.5735 },
                  set: { volumeML = $0 * 29.5735 }
                ),
                in: 1...64,
                step: 0.5
              )
            }
          }
          .cardContainer()
        }
        .padding(.horizontal)
      }
      .navigationTitle("Edit Container")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .shelf {
        Button {
          var updated = container
          updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
          updated.volumeML = volumeML
          onSave(updated)
          dismiss()
        } label: {
          Text("Save")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(!isValid)
      }
    }
  }
}

#Preview {
  ManageContainersView()
}
