//
//  MenstrualCyclePhase.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import SwiftUI
import HealthKit

public enum MenstrualCyclePhase: Hashable {
  case menstrual
  case follicular
  case ovulation
  case luteal
  case unknown
}

public extension MenstrualCyclePhase {

  var name: String {
    switch self {
    case .menstrual:
      String(localized: "Menstrual Phase", bundle: Bundle.coreHealth)
    case .follicular:
      String(localized: "Follicular Phase", bundle: Bundle.coreHealth)
    case .ovulation:
      String(localized: "Ovulation Phase", bundle: Bundle.coreHealth)
    case .luteal:
      String(localized: "Luteal Phase", bundle: Bundle.coreHealth)
    case .unknown:
      String(localized: "Unknown", bundle: Bundle.coreHealth)
    }
  }

  var color: Color? {
    switch self {
    case .menstrual:
      return .mutedPink
    case .follicular:
      return .mutedPurple
    case .luteal:
      return .mutedIndigo
    case .ovulation:
      return .mutedBlue
    default:
      return nil
    }
  }

  var details: String? {
    switch self {
    case .menstrual:
      "This is when you're on your period. The uterine lining sheds, and hormone levels are at their lowest. It's a time for rest, gentle movement, and nourishment. Many people experience cramps, fatigue, and mood changes during this phase."
    case .follicular:
      "Following menstruation, the follicular phase continues until ovulation. During this phase, estrogen levels rise, and your body is preparing to release an egg. You'll likely feel more energized, focused, and social during this time."
    case .luteal:
      "Following ovulation, the luteal phase begins. Progesterone increases, preparing the body for a potential pregnancy. This phase is often associated with PMS symptoms, including mood swings, fatigue, and bloating. It's a time for rest and self-care."
    case .ovulation, .unknown:
      nil
    }
  }

  var coolFacts: [CoolFact] {
    switch self {
    case .menstrual:
      [
        CoolFact(
          title: "Rest and Recover",
          fact: "Your body is working hard during menstruation. It's okay to take it easy, prioritize rest, and listen to your body's need for downtime."
        ),
        CoolFact(
          title: "Iron-Rich Foods Help",
          fact: "You lose iron during your period, which can contribute to fatigue. Eating iron-rich foods like leafy greens, red meat, or beans can help replenish your levels."
        ),
        CoolFact(
          title: "Gentle Movement Can Help",
          fact: "Light exercise like walking, stretching, or gentle yoga can help reduce cramps and improve mood during your period by increasing blood flow and releasing endorphins."
        ),
        CoolFact(
          title: "Hormone Levels Are Lowest",
          fact: "Both estrogen and progesterone are at their lowest during menstruation, which can affect energy levels and mood. Be kind to yourself during this time."
        ),
        CoolFact(
          title: "Hydration Helps With Bloating",
          fact: "It might seem counterintuitive, but drinking more water during your period can actually help reduce bloating and water retention."
        ),
      ]
    case .follicular:
      [
        CoolFact(
          title: "Metabolism Slows Down",
          fact: "Your metabolism is slower during the follicular phase, meaning you may not feel as hungry. This can be a great time for nutrient-dense meals to fuel your body and brain without feeling the need to snack constantly."
        ),
        CoolFact(
          title: "It’s Your Energized Phase!",
          fact: "The follicular phase, starting from the first day of your period and lasting until ovulation, is often when you feel the most energized. Thanks to rising estrogen levels, you may notice a boost in mood, motivation, and stamina."
        ),
        CoolFact(
          title: "Brain Power Surge",
          fact: "Estrogen isn’t just good for your mood; it also enhances cognitive functions like memory and focus. This is a great time to tackle challenging tasks or creative projects!"
        ),
        CoolFact(
          title: "Skin Glows Brighter",
          fact: "As estrogen increases during the follicular phase, it can improve skin elasticity and moisture, often resulting in a natural glow. Your skin may feel smoother and more hydrated."
        ),
        CoolFact(
          title: "You’re More Social",
          fact: "You might feel more confident and social during this phase. Estrogen boosts dopamine and serotonin levels, which can make you feel more outgoing and positive."
        ),
        CoolFact(
          title: "Workout Like a Boss",
          fact: "During the follicular phase, your body is primed for intense exercise. You’re likely to feel stronger, recover faster, and build muscle more efficiently, making it the perfect time for high-intensity workouts."
        ),
      ]
    case .luteal:
      [
        CoolFact(
          title: "Metabolism Boost",
          fact: "Your body burns more calories during the luteal phase—up to 100-300 more calories a day than usual! This is due to the increased metabolic demands from the rise in progesterone. If you’re trying to lose weight, now is a good time to really dial in your nutrition plan adherence so you can take advantage of this!"
        ),
        CoolFact(
          title: "Cravings on High Alert",
          fact: "Feeling a sudden craving for chocolate or carbs? That’s because your metabolism speeds up in the luteal phase. Your body burns more calories, which can trigger hunger and cravings, especially for comfort foods. Try to work the foods you crave into your nutrition plan to prevent those cravings from getting out of control."
        ),
        CoolFact(
          title: "A Perfect Time for Gentle Workouts",
          fact: "While high-energy workouts might feel tougher during the luteal phase, it’s a great time for more mindful activities like yoga, Pilates, or walking. If you life weights, consider adding a deload week. These will help you stay active without pushing your body too hard."
        ),
        CoolFact(
          title: "Your Emotions Are More Intense",
          fact: "The luteal phase is when premenstrual symptoms (PMS) like mood swings can kick in, but it's also a time when you might feel emotions more deeply. It’s a great opportunity to tap into self-care and mindfulness practices to manage any mood changes."
        ),
        CoolFact(
          title: "Time to Chill",
          fact: "The luteal phase, which starts after ovulation and lasts until your period, is a natural time for rest and reflection. Progesterone rises, making you feel more introspective and less driven by the high energy of the follicular phase. Progesterone during the luteal phase prepares the body for a potential pregnancy. Even if you're not trying to conceive, this hormone is responsible for making you feel a little more cautious, reflective, and nurturing."
        ),
        CoolFact(
          title: "Boost Your Sleep Hygiene",
          fact: "Progesterone is known to have a calming effect, which can make you feel sleepier, especially in the later luteal phase. Use this time to catch up on rest and prioritize a good sleep routine."
        ),
      ]
    default: []
    }
  }
}

public extension MenstrualCyclePhase {
  struct CoolFact: Identifiable, Hashable {
    public var id: Int { hashValue }

    public let title: String
    public let fact: String
  }
}
