//
//  AppSiteAssociationController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-10-12.
//

import Vapor
import Foundation

struct AppSiteAssociationController {
  let app: Application
}

extension AppSiteAssociationController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group(".well-known") { (wellKnown) in
      wellKnown.get("apple-app-site-association") { (request) in
        try await request.fileio.asyncStreamFile(at: app.appleAppSiteAssociationFilepath)
      }
    }
  }
}
