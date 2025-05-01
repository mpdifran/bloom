//
//  WorkoutRoutePolyline.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-18.
//

import Foundation
import MapKit
import SwiftUI
import CoreHealth

struct WorkoutRoutePolyline: UIViewRepresentable {
  let routes: [WorkoutRoute]

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()

    for route in routes {
      let polyline = MKPolyline(
        coordinates: route.locations.map { $0.coordinate },
        count: route.locations.count)
      mapView.addOverlay(polyline)
    }

    mapView.delegate = context.coordinator
    return mapView
  }

  func updateUIView(_ uiView: MKMapView, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if let polyline = overlay as? MKPolyline {
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 3
        return renderer
      }
      return MKOverlayRenderer()
    }
  }
}
