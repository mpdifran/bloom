//
//  ModelPricing.swift
//  Bloom-Backend
//
//  Created by Claude on 2026-08-09.
//

import Foundation
import OpenAIKit

/// Published OpenAI API rates, in micro-dollars (µ$, one millionth of a USD) per 1M tokens.
///
/// Rates are stored as integers so budget math never accumulates floating point drift. Cached input
/// is not modelled: neither `Usage` nor `Response.Usage` reports cached token counts, so every input
/// token is billed at the uncached rate. That makes recorded cost an over-estimate whenever prompt
/// caching kicks in, which is the safe direction for a budget cap.
struct ModelPricing: Sendable {
  /// µ$ charged per 1M input tokens.
  let inputPerMillion: Int
  /// µ$ charged per 1M output tokens. Reasoning tokens are billed as output.
  let outputPerMillion: Int
}

extension ModelPricing {

  /// Rates as published at https://developers.openai.com/api/docs/pricing (checked 2026-08-09).
  /// Keyed by `ModelID.id`. Update alongside any model map change.
  static let table: [String: ModelPricing] = [
    "gpt-5.6-sol": ModelPricing(inputPerMillion: 5_000_000, outputPerMillion: 30_000_000),
    "gpt-5.6-terra": ModelPricing(inputPerMillion: 2_000_000, outputPerMillion: 12_000_000),
    "gpt-5.6-luna": ModelPricing(inputPerMillion: 200_000, outputPerMillion: 1_200_000),
    "gpt-5": ModelPricing(inputPerMillion: 1_250_000, outputPerMillion: 10_000_000),
    "gpt-5-mini": ModelPricing(inputPerMillion: 250_000, outputPerMillion: 2_000_000),
    "gpt-5-nano": ModelPricing(inputPerMillion: 50_000, outputPerMillion: 400_000)
  ]

  /// The rate used when a model is missing from `table`. Deliberately the most expensive model we
  /// know about, so an unpriced model burns budget fast rather than silently running free.
  static let unknown = ModelPricing(inputPerMillion: 5_000_000, outputPerMillion: 30_000_000)

  static func pricing(for model: ModelID) -> ModelPricing {
    table[model.id] ?? unknown
  }

  /// Cost of a single completion in µ$, rounded up so sub-µ$ calls still register.
  static func cost(model: ModelID, inputTokens: Int, outputTokens: Int) -> Int {
    let pricing = pricing(for: model)
    let input = (max(0, inputTokens) * pricing.inputPerMillion + 999_999) / 1_000_000
    let output = (max(0, outputTokens) * pricing.outputPerMillion + 999_999) / 1_000_000
    return input + output
  }
}
