/**
 ProteinCallManager.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file calls data from the API and formats it
 History:
 Mar 18, 2025: File creation
 Mar 18, 2025: Retrieved food data
 Mar 20, 2025: Added JSON parsing
*/


import Foundation


struct ProteinCallManager {
    /**
     A structure that interacts with the Nutritionix API to retrieve, process, and manage protein information about foods.
     */
    
    let headers = [
        "Content-Type": "application/x-www-form-urlencoded",
        "x-app-id": Bundle.main.object(forInfoDictionaryKey: "NUTRITIONIX_APP_ID") as? String ?? "",
        "x-app-key": Bundle.main.object(forInfoDictionaryKey: "NUTRITIONIX_APP_KEY") as? String ?? "",
        "x-remote-user-id": "0"
    ]
    
    
    func prepareRequest(requestString: String?, urlString: String, httpMethod: String) -> URLRequest? {
        /**
         Prepares a request for the Nutritionix API given user-inputed information.
     
         - Parameters:
            - requestString (Optional String): The identifier string to be sent to the API.
            - urlString (String): The base URL string of the API endpoint.
            - httpMethod (String): The HTTP method to use.
         
         - Returns: An optional URLRequest for the specified API call.
         */
        
        // If string is not nil
        if let query = requestString {
            
            // If HTTP method is "GET," the query must be appended to the URL; code from https://docx.syndigo.com/developers/docs/search-item-endpoint
            if httpMethod.uppercased() == "GET" {
                let url: URL
                if let upc = Int(query) {
                    url = URL(string: "\(urlString)?upc=\(upc)")!
                } else {
                    url = URL(string: "\(urlString)?nix_item_id=\(query)")!
                }
                var request = URLRequest(url: url)
                request.httpMethod = httpMethod
                request.allHTTPHeaderFields = headers
                return request
            }
            
            // Otherwise, encode the query string into Data and set it as the HTTP body; code from https://docx.syndigo.com/developers/docs/natural-language-for-nutrients
            else {
                let url = URL(string: urlString)!
                let bodyString = "query=\(query)"
                let bodyData = bodyString.data(using: .utf8)
                var request = URLRequest(url: url)
                request.httpBody = bodyData
                request.httpMethod = httpMethod
                request.allHTTPHeaderFields = headers
                return request
            }
        }
        return nil
    }
    
    
    func performFoodRequest(request: URLRequest?, completion: @escaping ([[String?]]) -> Void) {
        /**
         Performs a food request for the Nutrionix API with the prepared information.
         
         - Parameters:
            - request (Optional URLRequest): Previously prepared to search the food.
            - completion ([[Optional String]]): A closure called with the first array containing the un-branded food names, and the second containing the branded name IDs.
         */
        
        var proteinRequests: [[String?]] = [[], []]
        
        // Make sure request is not nil
        if let safeRequest = request {
            
            // Create a data task with the given request
            let task = URLSession.shared.dataTask(with: safeRequest) { (data, response, error) in

                // If data is received successfully
                if let safeData = data {

                    // Parse JSON into food identifiers
                    proteinRequests = self.parseFoodJSON(foodData: safeData)
                }

                // Call the completion handler possibly with food identifiers later used for protein requests
                completion(proteinRequests)
            }
            
            // Start task
            task.resume()
        }
    }
    
    
    func parseFoodJSON(foodData: Data) -> [[String?]] {
        /**
         Parses JSON data from the Nutritionix API into a list of food names and IDs.
         
         - Parameters:
            - foodData (Data): The raw data retrieved from the API.
         
         - Returns: A 2D array with list of common food names, and a second list of branded food IDs.
         */
        
        var foodList: [[String?]] = [[], []]
        let decoder = JSONDecoder()
        
        // Try to decode results from Nutritionix API from searching a food string
        do {
            let decodedData = try decoder.decode(FoodData.self, from: foodData)
            
            // Append food identifiers to the food list
            for food in decodedData.common {
                foodList[0].append(food.food_name)
            }
            for food in decodedData.branded {
                foodList[1].append(food.nix_item_id)
            }
        } catch {}
        return foodList
    }
    
    
    func performProteinRequest(request: URLRequest?, completion: @escaping (Food?) -> Void) {
        /**
         Performs a protein request for the Nutrionix API with the prepared information.
         
         - Parameters:
            - request (Optional URLRequest): Previously prepared to search the food.
            - completion (Optional Food): A closure called with Food objects the user can log.
         */
        
        var proteinFood: Food? = nil
        
        // Make sure request is not nil
        if let safeRequest = request {
            
            // Create a data task with the given request
            let task = URLSession.shared.dataTask(with: safeRequest) { (data, response, error) in
                
                // If data is received successfully
                if let safeData = data {
                    
                    // Parse JSON into a Food object
                    if let food = self.parseProteinJSON(proteinData: safeData) {
                        proteinFood = food
                    }
                }
                
                // Call the completion handler possibly with functional Food object users can log
                completion(proteinFood)
            }
            
            // Start task
            task.resume()
        }
    }
    
    
    func parseProteinJSON(proteinData: Data) -> Food? {
        /**
         Parses JSON data from the Nutritionix API to retrieve food, fiber, and measurement information.
         
         - Parameters:
            - proteinData (Data): The raw data retrieved from the API.
         
         - Returns: An Optional Food object parsed from the JSON.
         */
        
        let decoder = JSONDecoder()
        
        // Try to decode food-specific nutrient data from Nutritionix API
        do {
            let decodedData = try decoder.decode(ProteinData.self, from: proteinData)
            
            // Create Food object from Nutrionix API JSON
            let food = decodedData.foods[0]
            let foodName = food.food_name
            let brandName = food.brand_name ?? "unbranded"
            let servingProtein = food.nf_protein
            let servingQuantity = food.serving_qty
            let servingUnit = food.serving_unit
            let servingGrams = food.serving_weight_grams
            
            // Create property values for the Food object's selected measure
            let servingExpression = "\(servingQuantity) \(servingUnit)"
            let servingMeasure = Measure(measureExpression: servingExpression, measureMass: servingGrams)
            
            // Calculate the protein per gram for the Food object
            let proteinPerGram = servingProtein/servingGrams
            
            var altMeasures: [Measure] = []
            altMeasures.append(servingMeasure)
            
            // Create Measure objects from Nutrionix API JSON
            if let toParseMeasures = food.alt_measures {
                for altMeasure in toParseMeasures {
                    let measureQuantity = altMeasure.qty
                    let measure = altMeasure.measure
                    let measureMass = altMeasure.serving_weight
                    let altMeasureExpression = "\(measureQuantity) \(measure)"
                    let parsedMeasure = Measure(measureExpression: altMeasureExpression, measureMass: measureMass)
                    altMeasures.append(parsedMeasure)
                }
            }
            
            let parsedFood = Food(food: foodName, proteinPerGram: proteinPerGram, brandName: brandName, measures: altMeasures, selectedMeasure: servingMeasure, multiplier: 1.0, consumptionTime: nil)
            return parsedFood
        }
        
        // If an error occurs, return nil
        catch {
            return nil
        }
    }
}
