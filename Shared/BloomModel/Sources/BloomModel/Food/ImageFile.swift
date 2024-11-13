//
//  ImageFile.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation

public struct ImageFile: Codable {
    public let data: Data
    public let fileExtension: String

    public init(data: Data, fileExtension: String) {
        self.data = data
        self.fileExtension = fileExtension
    }
}
