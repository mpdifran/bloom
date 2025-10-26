//
//  ImageStorage.swift
//  Bloom-Backend
//
//  Created by Mike Welsh on 2024-11-24.
//

import BloomModel
import Vapor
import SotoS3


/// Explicit enum for storage so that we limit the number of folders in our storage.
enum StoragePath: String {
  case nutritionLabel = "nutrition-label"
  case foodPackaging = "food-packaging"
  case chatImages = "chat-images"
  case magicScanner = "magic-scanner"
}

protocol ImageStorage: Sendable {

  /// Store the provided image file
  /// - Parameters:
  ///   - image: The image to store
  ///   - path: Where to store the image.
  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata

  func generateImageURL(
    fileName: String,
    path: StoragePath,
    expiration: TimeAmount
  ) async throws -> URL?

  /// Retrieve image data from storage
  /// - Parameters:
  ///   - fileName: The name of the file to retrieve
  ///   - path: The storage path where the file is located
  func retrieveImage(fileName: String, path: StoragePath) async throws -> ImageFile?

  /// Delete a single image from storage
  /// - Parameters:
  ///   - fileName: The name of the file to delete
  ///   - path: The storage path where the file is located
  func deleteImage(fileName: String, path: StoragePath) async throws

  /// Delete old images from storage
  /// - Parameters:
  ///   - date: Delete images older than this date
  ///   - path: The storage path to clean up
  /// - Returns: Number of images deleted
  func deleteOldImages(olderThan date: Date, path: StoragePath) async throws -> Int
}

struct S3Storage: ImageStorage {

  let bucketName: String
  let s3: S3
  let logger: Logger
  let allocator: ByteBufferAllocator

  init(
    bucketName: String,
    s3: S3,
    logger: Logger,
    allocator: ByteBufferAllocator
  ) {
    self.bucketName = bucketName
    self.s3 = s3
    self.logger = logger
    self.allocator = allocator
  }

  private let imageProcessing = ImageProcessor()

  func store(image: ImageFile, path: StoragePath) async throws -> ImageFileMetadata {
    guard let imageType = imageProcessing.determineImageType(image.data) else {
      throw Abort(.badRequest, reason: "Unsupported image type")
    }

    let filename = "\(UUID().uuidString).\(imageType)"

    let putObjectRequest = S3.PutObjectRequest(
        body: .data(image.data, byteBufferAllocator: allocator),
        bucket: bucketName,
        key: "\(path.rawValue)/\(filename)"
    )

    _ = try await s3.putObject(putObjectRequest)
    logger.info("Saved image to S3: \(bucketName) - \(putObjectRequest.key)")

    return ImageFileMetadata(filename: filename, data: image.data)
  }

  func generateImageURL(
    fileName: String,
    path: StoragePath,
    expiration: TimeAmount
  ) async throws -> URL? {
    let objectKey = "\(path)/\(fileName)"
    let region = s3.region
    let url = URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(objectKey)")!
    do {
      /// Reference: https://soto.codes/2020/12/presigned-urls.html
      let image = try await s3.signURL(
        url: url,
        httpMethod: .GET,
        expires: expiration
      )
      logger.info("Successfully generated signed URL for S3: \(image)")
      return image
    } catch {
      logger.error("Failed to create S3 signed URL: \(error)")
      return nil
    }
  }

  func retrieveImage(fileName: String, path: StoragePath) async throws -> ImageFile? {
    let objectKey = "\(path.rawValue)/\(fileName)"

    let getObjectRequest = S3.GetObjectRequest(
      bucket: bucketName,
      key: objectKey
    )

    let response = try await s3.getObject(getObjectRequest)

    guard let data = response.body?.asData() else {
      logger.warning("No data in S3 response for: \(objectKey)")
      return nil
    }

    guard let fileExtension = fileName.split(separator: ".").last.map(String.init) else {
      logger.warning("Could not determine file extension for: \(fileName)")
      return nil
    }

    return ImageFile(data: data, fileExtension: fileExtension)
  }

  func deleteImage(fileName: String, path: StoragePath) async throws {
    let objectKey = "\(path.rawValue)/\(fileName)"

    let deleteRequest = S3.DeleteObjectRequest(
      bucket: bucketName,
      key: objectKey
    )

    do {
      _ = try await s3.deleteObject(deleteRequest)
      logger.info("Deleted image from S3: \(objectKey)")
    } catch {
      logger.error("Failed to delete image from S3: \(error)")
      throw error
    }
  }

  func deleteOldImages(olderThan date: Date, path: StoragePath) async throws -> Int {
    let prefix = "\(path.rawValue)/"

    let listRequest = S3.ListObjectsV2Request(
      bucket: bucketName,
      prefix: prefix
    )

    do {
      let response = try await s3.listObjectsV2(listRequest)

      let oldObjects = response.contents?.filter { object in
        guard let lastModified = object.lastModified else { return false }
        return lastModified < date
      } ?? []

      guard !oldObjects.isEmpty else {
        logger.info("No old images to delete from S3 path: \(prefix)")
        return 0
      }

      let objectsToDelete = oldObjects.compactMap { $0.key }.map { S3.ObjectIdentifier(key: $0) }

      let deleteRequest = S3.DeleteObjectsRequest(
        bucket: bucketName,
        delete: S3.Delete(objects: objectsToDelete)
      )

      _ = try await s3.deleteObjects(deleteRequest)

      logger.info("Deleted \(objectsToDelete.count) old images from S3 path: \(prefix)")
      return objectsToDelete.count
    } catch {
      logger.error("Failed to delete old images from S3: \(error)")
      throw error
    }
  }
}
