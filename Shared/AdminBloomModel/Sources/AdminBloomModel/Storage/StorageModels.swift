import BloomModel
import Foundation

// MARK: - Storage Statistics

public struct StorageStats: Codable, Sendable {
  public let nutritionLabelStats: FolderStats
  public let foodPackagingStats: FolderStats
  public let chatImagesStats: FolderStats
  public let magicScannerStats: FolderStats

  public init(
    nutritionLabelStats: FolderStats,
    foodPackagingStats: FolderStats,
    chatImagesStats: FolderStats,
    magicScannerStats: FolderStats
  ) {
    self.nutritionLabelStats = nutritionLabelStats
    self.foodPackagingStats = foodPackagingStats
    self.chatImagesStats = chatImagesStats
    self.magicScannerStats = magicScannerStats
  }
}

public struct FolderStats: Codable, Sendable {
  public let fileCount: Int
  public let totalBytes: Int64

  public init(fileCount: Int, totalBytes: Int64) {
    self.fileCount = fileCount
    self.totalBytes = totalBytes
  }

  public var totalMB: Double {
    Double(totalBytes) / 1_048_576.0
  }
}

// MARK: - Orphaned Images

public struct OrphanedImageInfo: Codable, Sendable, Identifiable {
  public let filename: String
  public let path: String
  public let sizeBytes: Int64
  public let lastModified: Date?

  public var id: String { "\(path)/\(filename)" }

  public init(filename: String, path: String, sizeBytes: Int64, lastModified: Date?) {
    self.filename = filename
    self.path = path
    self.sizeBytes = sizeBytes
    self.lastModified = lastModified
  }

  public var sizeMB: Double {
    Double(sizeBytes) / 1_048_576.0
  }
}

// MARK: - Request/Response Types

public struct GetStorageStatsResponse: Codable, Sendable {
  public let stats: StorageStats

  public init(stats: StorageStats) {
    self.stats = stats
  }
}

public struct GetOrphanedImagesResponse: Codable, Sendable {
  public let orphanedImages: [OrphanedImageInfo]
  public let totalCount: Int
  public let totalBytes: Int64

  public init(orphanedImages: [OrphanedImageInfo], totalCount: Int, totalBytes: Int64) {
    self.orphanedImages = orphanedImages
    self.totalCount = totalCount
    self.totalBytes = totalBytes
  }

  public var totalMB: Double {
    Double(totalBytes) / 1_048_576.0
  }
}

public struct DeleteOrphanedImagesRequest: Codable, Sendable {
  public let imagePaths: [String] // Format: "path/filename"

  public init(imagePaths: [String]) {
    self.imagePaths = imagePaths
  }
}

public struct DeleteOrphanedImagesResponse: Codable, Sendable {
  public let deletedCount: Int
  public let errors: [String]

  public init(deletedCount: Int, errors: [String]) {
    self.deletedCount = deletedCount
    self.errors = errors
  }
}

public struct GetLargeImagesRequest: Codable, Sendable {
  public let thresholdBytes: Int64 // Default: 500KB = 512000 bytes

  public init(thresholdBytes: Int64 = 512_000) {
    self.thresholdBytes = thresholdBytes
  }
}

public struct GetLargeImagesResponse: Codable, Sendable {
  public let largeImages: [OrphanedImageInfo] // Reusing the same model
  public let totalCount: Int
  public let totalBytes: Int64

  public init(largeImages: [OrphanedImageInfo], totalCount: Int, totalBytes: Int64) {
    self.largeImages = largeImages
    self.totalCount = totalCount
    self.totalBytes = totalBytes
  }

  public var totalMB: Double {
    Double(totalBytes) / 1_048_576.0
  }
}

public struct GeneratePresignedURLRequest: Codable, Sendable {
  public let filename: String
  public let path: String

  public init(filename: String, path: String) {
    self.filename = filename
    self.path = path
  }
}

public struct GeneratePresignedURLResponse: Codable, Sendable {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }
}

public struct ReplaceImageRequest: Codable, Sendable {
  public let filename: String
  public let path: String
  public let imageData: ImageFile

  public init(filename: String, path: String, imageData: ImageFile) {
    self.filename = filename
    self.path = path
    self.imageData = imageData
  }
}
