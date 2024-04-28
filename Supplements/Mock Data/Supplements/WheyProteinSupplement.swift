//
//  WheyProteinSupplement.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-28.
//

import Foundation

extension SupplementModel {
    static let wheyProteinSupplement = SupplementModel(
        name: "Whey Protein",
        image: .wheyProtein,
        whatIsIt: "Whey protein is a collection of proteins found in whey, a byproduct of cheesemaking. When a coagulant (usually rennet) is added to milk, the curds (casein) and whey separate; whey protein is the water-soluble part of milk. Whey protein is often consumed as a supplement in the form of dry powders with various levels of processing that affect how concentrated a source of protein they are and how fast they’re absorbed. There are three main types of whey protein: whey concentrate, whey isolate, and whey hydrolysate.",
        benefits: """
Whey is considered to be a high-quality, well-absorbed source of protein with benefits that are similar to those of increasing protein intake in general, such as augmenting muscle gain when paired with resistance training, limiting muscle loss during low-calorie diets/aging, and modestly limiting fat gain during periods of excessive calorie intake (e.g., “bulking”).
Whey contains high levels of the amino acid leucine, which is the most proteogenic (capable of increasing muscle protein synthesis or MPS) amino acid. As such, whey may be more potent at stimulating MPS than other protein types.[31] Furthermore, supplementing with whey may benefit blood pressure,[32] endothelial function,[33] and appears to improve several glycemic- and lipid-related biomarkers in adults with type 2 diabetes and other metabolic conditions.[34][35][36]
""",
        drawbacks: """
Some individuals may experience digestive discomfort, bloating, gas, or diarrhea after consuming whey protein, but this will depend on the dose and one’s tolerance. Whey protein concentrate contains the milk sugar lactose, so individuals with lactose intolerance may want to avoid this form of whey protein in favor of isolate/hydrolysate (which don’t contain fat and contain very little lactose, making these forms of whey protein tolerable by all but the most lactose-sensitive individuals).
Whey (and protein in general) does not harm the liver or kidneys, but high-protein diets can exacerbate or accelerate pre-existing damage. People with damaged livers or kidneys should exercise caution when increasing protein intake quickly without the guidance of a doctor. See more below: “Can eating too much protein be bad for you?”
Furthermore, a 2018 report on protein powders found that of the 134 products tested, over 70% of them had detectable levels of lead and cadmium. However, no data were reported on whey protein powders specifically and it should be noted that “detectable” does not necessarily mean harmful.[37]
""",
        dosageInformation: """
Optimal protein intake will vary depending on one’s unique goals, and you can use our protein intake calculator to estimate your optimal daily protein intake, which is based on the evidence presented in our optimal protein intake guide.
"""
    )
}
