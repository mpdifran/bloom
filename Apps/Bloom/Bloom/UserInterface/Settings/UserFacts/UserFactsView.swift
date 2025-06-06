//
//  UserFactsView.swift
//  Bloom
//
//  Created by Claude on 2025-06-06.
//

import SwiftUI
import DataContainer
import BloomFoundation
import SFSafeSymbols
import SwiftData

struct UserFactsView: View {
  @Query(sort: \UserFact.dateAdded, order: .reverse) private var userFacts: [UserFact]
  @State private var error: Error?
  
  var body: some View {
    NavigationStack {
      Group {
        if userFacts.isEmpty {
          emptyStateView
        } else {
          userFactsList
        }
      }
      .navigationTitle("User Facts")
      .navigationBarTitleDisplayMode(.inline)
      .alert(error: $error)
    }
  }
}

private extension UserFactsView {
  
  var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemSymbol: .personTextRectangle)
        .font(.system(size: 48))
        .foregroundStyle(.secondary)
      
      Text("No User Facts")
        .font(.title2)
        .fontWeight(.semibold)
      
      Text("When you share personal information with Bud, it will be stored here for future reference.")
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .groupedBackground()
  }
  
  var userFactsList: some View {
    BloomScrollView {
      ForEach(userFacts) { userFact in
        UserFactCell(userFact: userFact.asDTO()) {
          deleteUserFact(userFact)
        }
      }
    }
  }
  
  func deleteUserFact(_ userFact: UserFact) {
    Task {
      do {
        let userFactModelActor = UserFactModelActor.standard()
        try await userFactModelActor.deleteUserFact(withID: userFact.id)
      } catch {
        self.error = error
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    UserFactsView()
  }
}
