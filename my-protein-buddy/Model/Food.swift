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

struct FoodData: Decodable {
    /**
     A structure that reads the food data from a JSON response and separates the food items in different categories.
     
     - Properties:
        - common (Array): An array of common food items.
        - branded (Array): An array of branded food products.
    */
    
    let common: [CommonFoodRequest]
    let branded: [BrandedFoodRequest]
}

struct CommonFoodRequest: Decodable {
    /**
     A structure that reads common food item returned from a JSON response.
     
     - Properties:
        - food_name (String): The name of the food item.
    */
    
    let food_name: String
}

struct BrandedFoodRequest: Decodable {
    /**
     A structure that reads a branded food product returned from a JSON response.
     
     - Properties:
        - nix_item_id (String): The unique Nutritionix API identifier for the branded item in the food database.
    */
    
    let nix_item_id: String
}

struct ProteinData: Decodable {
    /**
     A structure that reads the root object returned by a JSON response.
     
     - Properties:
        - food (Array): An array of raw food items containing protein and measurement information.
     */
    
    let foods: [RawFood]
}

struct RawFood: Decodable {
    /**
     A structure that organizes the properties of food items read from a JSON reponse.
     
     - Properties:
         - food_name (String): The name of the food item.
         - nf_dietary_fiber (Double): The amount of protein per unit.
         - brand_name (Optional String): The brand of the food, if applicable.
         - alt_measures (Optional Array): An array of alternative measurement units, if available.
         - serving_qty (Int): The default serving quantity.
         - serving_unit (String): The unit for the default serving quantity.
         - serving_weight_grams (Double): The weight in grams for the default serving size.
     */
    
    let food_name: String
    let nf_protein: Double
    let brand_name: String?
    let alt_measures: [RawMeasure]?
    let serving_qty: Int
    let serving_unit: String
    let serving_weight_grams: Double
}
