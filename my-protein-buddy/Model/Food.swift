/**
 Food.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file initialises the food structures
 History:
 Mar 7, 2025: File creation
 Mar 18, 2025: Added food structures
*/

import Foundation

struct Food: Codable {
    /**
     A structure that organises properties of food items, and allows properties to be readable and writable.

     - Properties:
        - food (String): The name of the food item.
        - proteinPerGram (Double): The amount of protein per gram for the food item.
        - brandName (String): The brand for the food item.
        - measures (Array): An array of potential measurement units.
        - selectedMeasure (Measure): The measurement unit selected by the user.
        - multiplier (Double): A value to convert between measures.
        - consumptionTime (Optional String): The timestamp at which the food was consumed, if applicable.
     */

    let food: String
    let proteinPerGram: Double
    let brandName: String
    let measures: [Measure]
    var selectedMeasure: Measure
    var multiplier: Double
    var consumptionTime: String?
}

// MARK: - FatSecret Search Response
struct FSSearchResponse: Decodable {
    /**
     A structure that reads the search results from a FatSecret API JSON response.

     - Properties:
        - foods (FSFoodList): The search results container.
    */

    let foods: FSFoodList
}

struct FSFoodList: Decodable {
    /**
     A structure that contains the array of food items from a FatSecret API JSON response.

     - Properties:
        - food (Array): An array of food search results.
    */

    let food: [FSFoodSearchItem]
}

struct FSFoodSearchItem: Decodable {
    /**
     A structure that reads a food item from the FatSecret search results.

     - Properties:
        - food_id (String): The unique FatSecret identifier for the food item.
        - food_name (String): The name of the food item.
        - brand_name (Optional String): The brand name, if applicable.
        - food_type (String): The type of food (Generic or Brand).
    */

    let food_id: String
    let food_name: String
    let brand_name: String?
    let food_type: String
}

// MARK: - FatSecret Food Detail Response
struct FSFoodDetailResponse: Decodable {
    /**
     A structure that reads the detailed food data from a FatSecret API JSON response.

     - Properties:
        - food (FSFoodDetail): The detailed food object.
    */

    let food: FSFoodDetail
}

struct FSFoodDetail: Decodable {
    /**
     A structure that contains the detailed food information from a FatSecret API JSON response.

     - Properties:
        - food_id (String): The unique FatSecret identifier.
        - food_name (String): The name of the food item.
        - brand_name (Optional String): The brand name, if applicable.
        - servings (FSServingsContainer): The servings container.
    */

    let food_id: String
    let food_name: String
    let brand_name: String?
    let servings: FSServingsContainer
}

struct FSServingsContainer: Decodable {
    /**
     A structure that wraps the serving data, handling both single and array responses.

     - Properties:
        - serving (Array): An array of serving options.
    */

    let serving: [FSServing]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // FatSecret may return a single object or an array for "serving"
        if let array = try? container.decode([FSServing].self, forKey: .serving) {
            serving = array
        } else if let single = try? container.decode(FSServing.self, forKey: .serving) {
            serving = [single]
        } else {
            serving = []
        }
    }

    enum CodingKeys: String, CodingKey {
        case serving
    }
}

struct FSServing: Decodable {
    /**
     A structure that reads a serving option from the FatSecret API JSON response.

     - Properties:
        - serving_description (String): A textual description of the serving (e.g. "1 breast").
        - metric_serving_amount (Optional String): The mass in grams for the serving.
        - metric_serving_unit (Optional String): The unit for the metric serving (e.g. "g").
        - number_of_units (String): The number of units for this serving.
        - measurement_description (String): The measurement name (e.g. "breast").
        - protein (String): The protein content for this serving.
    */

    let serving_description: String
    let metric_serving_amount: String?
    let metric_serving_unit: String?
    let number_of_units: String
    let measurement_description: String
    let protein: String
}
