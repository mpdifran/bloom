//
//  Application+APNs.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-19.
//

import Foundation
import Vapor
import APNS
import VaporAPNS
import APNSCore
import JWTKit

extension Application {

  func configureAPNs() throws {
    let apnsConfig = APNSClientConfiguration(
      authenticationMethod: .jwt(
        privateKey: try .loadFrom(string: bloomAPNsPrivateKey),
        keyIdentifier: bloomAPNsJWKID,
        teamIdentifier: appleTeamID
      ),
      environment: .development
    )

    apns.containers.use(
      apnsConfig,
      eventLoopGroupProvider: .shared(eventLoopGroup),
      responseDecoder: JSONDecoder(),
      requestEncoder: JSONEncoder(),
      as: .default
    )
  }
}
