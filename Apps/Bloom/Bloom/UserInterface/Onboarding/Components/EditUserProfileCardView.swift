//
//  EditUserProfileCardView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-17.
//

import SwiftUI
import AppUI
import CoreHealth

struct EditUserProfileCardView: View {

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack {
      UserProfilePhotoView(canEdit: true)

      TextField("", text: $healthManager.name, prompt: Text("Name (Optional)"))
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .submitLabel(.done)
        .textFieldStyle(.roundedBorder)

      CurrentThemeView()
        .selectable()
        .onTapGesture {
          presentedSheet = ThemeSelectionCard().asAny
        }
    }
    .cardContainer()
    .sheet($presentedSheet)
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      Spacer()
      EditUserProfileCardView()
      Spacer()
    }
    .padding()
    .horizontallyCentered()
    .groupedBackground()
  }
}
