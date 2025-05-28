/**
 Measure.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file initialises the measure structures
 History:
 Mar 18, 2025: File creation
 Mar 18, 2025: Added measure structures
*/

import Foundation

struct Measure: Codable {
    /**
     A structure that represents the measurement unit that is both readable and writing for a food item.
     
     - Properties:
         - measureExpression (String): A textual representation of the measurement.
         - measureMass (Double): The mass in grams for the measurement.
     */
    
    let measureExpression: String
    let measureMass: Double
}

struct RawMeasure: Decodable {
    /**
     A structure that reads the raw measurement units from the Nutritionix API.
     
     - Properties:
         - serving_weight (Double): The mass in grams of the raw serving.
         - qty (Int): The quantity of raw servings.
         - measure (String): The name of the raw serving measure.
     */
    
    let serving_weight: Double
    let qty: Int
    let measure: String
}
