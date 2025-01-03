//
//  ImageFile.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation

public struct ImageFile: Codable, Sendable {
    public let data: Data
    // TODO: The file extension shouldn't need to be provided; image parsing library should be able to determine
    // the image type from the data.
    public let fileExtension: String

    public init(data: Data, fileExtension: String) {
        self.data = data
        self.fileExtension = fileExtension
    }
}
