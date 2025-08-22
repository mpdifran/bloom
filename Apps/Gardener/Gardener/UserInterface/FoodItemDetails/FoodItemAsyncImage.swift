//
//  FoodItemAsyncImage.swift
//  Gardener
//
//  Created by Zach Radford on 2025-01-04.
//

import AppUI
import SwiftUI

struct FoodItemAsyncImage: View {

  let url: URL?
  let replacementImage: NSImage?
  let rotationAngle: Double
  @Binding var alertDetails: AlertDetails?

  var body: some View {
    if let replacementImage {
      Image(nsImage: replacementImage)
        .resizable()
        .scaledToFit()
        .rotationEffect(.degrees(rotationAngle))
    } else if let url {
      AsyncImage(url: url) { phase in
        switch phase {
        case .empty:
          VStack {
            Spacer()
            ProgressView()
              .horizontallyCentered()
            Spacer()
          }
          .frame(minHeight: 200)
        case .success(let image):
          ZStack(alignment: .topTrailing) {
            image
              .resizable()
              .scaledToFit()
              .rotationEffect(.degrees(rotationAngle))
          }
        case .failure(let error):
          ContentUnavailableView {
            Label("Failed to Load Image", systemImage: "photo.badge.exclamationmark.fill")
          } description: {
            VStack {
              Text("The image failed to load")
              Text(error.localizedDescription)
              Text(url.absoluteString)
                .foregroundStyle(.blue)
                .textSelection(.enabled)
            }
          } actions: {
            Button("Copy URL to Clipboard") {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(url.absoluteString, forType: .string)
              alertDetails = AlertDetails(
                title: "Copied!",
                message: "Copied the URL to your clipboard."
              )
            }
            .buttonStyle(.borderedProminent)
          }
        @unknown default:
          Text("Unknown error occurred")
        }
      }
    } else {
      Text("Not Found")
    }
  }
}
