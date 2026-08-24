//
//  WebDomainClassification.swift
//  Bloom-Backend
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

/// What the classifier returns for one domain.
struct WebDomainClassification: Codable, Sendable {
  let domain: String
  let category: WebDomainReputation.Category
  /// 0-1. Only a high score on an unambiguous category is allowed to block anything on its own.
  let confidence: Double
  /// A short rationale, kept on the row so a block can be explained later.
  let reason: String
  /// How the site would like to be named - "Tripadvisor" rather than "tripadvisor.ca".
  let siteName: String?
}

struct WebDomainClassificationBatch: Codable, Sendable {
  let classifications: [WebDomainClassification]
}

extension ResponseSchema {

  static let webDomainClassification = ResponseSchema(
    name: "webDomainClassification",
    schema: Schema.Object(
      properties: [
        "classifications": Schema.Parameter(
          description: "One entry per domain given, in any order. Every domain must appear exactly once.",
          arrayOf: Schema.Item.object(
            Schema.Object(
              properties: [
                "domain": Schema.Parameter(
                  type: .string,
                  description: "The domain being classified, copied exactly as given."
                ),
                "category": Schema.Parameter(
                  enum: WebDomainReputation.Category.self,
                  description: """
                    What the site primarily is. Use 'safe' for anything ordinary - news, retail, \
                    restaurants, reference, blogs, medical or research sites. Use 'adult', \
                    'gambling', 'illegal' or 'malwareOrSpam' only when that is unmistakably the \
                    site's main purpose. Use 'lowQualityHealth' for sites whose main business is \
                    selling supplements or promoting unevidenced health claims. Use 'unknown' if \
                    you genuinely do not recognize the domain.
                    """
                ),
                "confidence": Schema.Parameter(
                  type: .number,
                  description: "0 to 1. How certain you are of the category. Be honest - low confidence is expected for domains you do not recognize."
                ),
                "reason": Schema.Parameter(
                  type: .string,
                  description: "One short sentence explaining the category. Under 100 characters."
                ),
                "siteName": Schema.Parameter(
                  type: .string,
                  description: "The site's usual display name, e.g. 'Tripadvisor' for tripadvisor.ca. Use the domain itself if unsure."
                ),
              ],
              required: ["domain", "category", "confidence", "reason", "siteName"]
            )
          )
        )
      ],
      required: ["classifications"]
    )
  )
}

extension String.Prompt {

  /// Deliberately asks only what a domain name can answer.
  ///
  /// The classifier never sees the page. Fetching arbitrary URLs server-side would be an SSRF hole
  /// and a second untrusted-content ingestion point, and domain plus title is enough to catch what
  /// this is actually for - adult, gambling and piracy sites, which are lexically obvious.
  static let webDomainClassifier = """
    You classify web domains so a health app can decide whether to show them as a citation.

    You are given only domain names and, where known, the title of a page that was cited from that
    domain. You cannot browse. Judge from the domain and title alone, and say so with your
    confidence score when you are unsure.

    Be conservative. Most of the web is ordinary and should be 'safe' - news sites, retailers,
    restaurants, review sites, reference works, universities, hospitals, government pages, personal
    blogs. Only reach for 'adult', 'gambling', 'illegal' or 'malwareOrSpam' when that is plainly the
    site's main purpose, not merely something it mentions.

    'lowQualityHealth' is for sites whose business is selling supplements or pushing health claims
    without evidence. It is not for mainstream outlets that happen to have a wellness section, nor
    for legitimate retailers that also sell supplements. When in doubt, prefer 'safe' with a lower
    confidence - a human reviews anything uncertain, and wrongly flagging a real site is the more
    expensive mistake.

    Return exactly one entry per domain given.
    """
}
