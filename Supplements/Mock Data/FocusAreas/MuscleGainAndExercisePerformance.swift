//
//  MuscleGainAndExercisePerformance.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-18.
//

import Foundation

extension FocusAreaModel {
    static let muscleGainAndExercisePerformance = FocusAreaModel(
        title: "Muscle Gain",
        systemImage: "figure.strengthtraining.traditional",
        color: .red,
        information: """
There’s a holy trinity of exercise:
- Better performance
- More muscle
- Less fat
These are the primary goals of most exercise programs. So why are we covering muscle gain and exercise performance together and separately from fat loss?
There’s a simple answer — because the latter (fat loss) is merely associated with exercise. More precisely, the issue with fat loss is one of fuel: how do you convince your body to burn its precious energy stores? Exercise does help, but not as much, in itself, as a hypocaloric diet (i.e., eating less than you burn).[1]
To lose fat, exercise is a plus. To build muscle, exercise is a necessity. Any supplement that helps you exercise harder and longer can also help you build stronger muscles. And because stronger muscles allow you to exercise harder and longer, any supplement that promotes muscle growth can also benefit exercise performance.
Note that we said it can benefit exercise performance, but it not always does. The upper-body muscles of a wrestler would be a literal burden to a marathoner. The type of exercise that you undertake will influence the kind of muscle you grow, and the kind of muscle that you grow will make you fitter for some sports than for others.
Even similar sports can lead to very different musculatures. Running marathons is an aerobic activity and builds more “slow twitch” muscle fibers (more endurance than strength). Running sprints is an anaerobic activity and builds more “fast twitch” muscle fibers (more strength than endurance).
""",
        primary: [],
        secondary: [],
        promising: [],
        unproven: [.init(supplement: .capsaicinSupplement, context: "The potential of CAP as an ergogenic aid for endurance exercise may depend on the duration of exercise (e.g., 1500 meter or 10 km), the type of exercise (i.e., intermittent or continuous), and possibly the training status of the athlete. Currently, no strong conclusions can be drawn on the efficacy of CAP in improving endurance exercise performance.")],
        inadvisable: []
    )
}

extension FocusAreaModel {
    static let sleepBetter = FocusAreaModel(
        title: "Improve Sleep",
        systemImage: "bed.double.fill",
        color: .teal,
        information: "",
        primary: [],
        secondary: [],
        promising: [],
        unproven: [],
        inadvisable: []
    )
}

extension FocusAreaModel {
    static let brainHealth = FocusAreaModel(
        title: "Brain Health",
        systemImage: "brain.fill",
        color: .blue,
        information: "",
        primary: [],
        secondary: [],
        promising: [],
        unproven: [],
        inadvisable: []
    )
}

extension FocusAreaModel {
    static let anxiety = FocusAreaModel(
        title: "Anxiety",
        systemImage: "hand.raised.fill",
        color: .pink,
        information: "",
        primary: [],
        secondary: [],
        promising: [],
        unproven: [],
        inadvisable: []
    )
}
