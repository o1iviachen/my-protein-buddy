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
     A structure that interacts with the FatSecret API to retrieve, process, and manage protein information about foods.
     */

    private static var accessToken: String?
    private static var tokenExpiresAt: Date?

    let clientID = Bundle.main.object(forInfoDictionaryKey: "FATSECRET_CLIENT_ID") as? String ?? ""
    let clientSecret = Bundle.main.object(forInfoDictionaryKey: "FATSECRET_CLIENT_SECRET") as? String ?? ""


    func fetchAccessToken(completion: @escaping (String?) -> Void) {
        /**
         Fetches an OAuth 2.0 access token from the FatSecret API using the client credentials grant type. Caches the token until expiry.

         - Parameters:
            - completion (Optional String): A closure called with the access token, or nil if the request fails.
         */

        // Return cached token if still valid
        if let token = ProteinCallManager.accessToken,
           let expiresAt = ProteinCallManager.tokenExpiresAt,
           Date() < expiresAt {
            completion(token)
            return
        }

        let url = URL(string: "https://oauth.fatsecret.com/connect/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "grant_type=client_credentials&client_id=\(clientID)&client_secret=\(clientSecret)&scope=basic%20barcode"
        request.httpBody = bodyString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("[FatSecret] Token error: \(error)")
                completion(nil)
                return
            }
            guard let safeData = data else {
                print("[FatSecret] Token: no data")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: safeData) as? [String: Any],
                   let token = json["access_token"] as? String,
                   let expiresIn = json["expires_in"] as? Int {
                    ProteinCallManager.accessToken = token
                    ProteinCallManager.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn - 60))
                    completion(token)
                } else {
                    print("[FatSecret] Token response unexpected: \(String(data: safeData, encoding: .utf8) ?? "nil")")
                    completion(nil)
                }
            } catch {
                print("[FatSecret] Token parse error: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }


    func performFoodSearch(query: String, completion: @escaping ([FSFoodSearchItem]) -> Void) {
        /**
         Searches for foods using the FatSecret API.

         - Parameters:
            - query (String): The food name to search for.
            - completion (Array): A closure called with an array of food search items.
         */

        fetchAccessToken { token in
            guard let safeToken = token else {
                completion([])
                return
            }

            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let urlString = "https://platform.fatsecret.com/rest/foods/search/v1?search_expression=\(encodedQuery)&format=json&max_results=20"

            guard let url = URL(string: urlString) else {
                completion([])
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(safeToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("[FatSecret] Search error: \(error)")
                    completion([])
                    return
                }
                guard let safeData = data else {
                    print("[FatSecret] Search: no data")
                    completion([])
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(FSSearchResponse.self, from: safeData)
                    completion(decoded.foods.food)
                } catch {
                    print("[FatSecret] Search decode error: \(error)")
                    completion([])
                }
            }
            task.resume()
        }
    }


    func fetchFoodDetails(foodID: String, completion: @escaping (Food?) -> Void) {
        /**
         Fetches detailed food information from the FatSecret API and parses it into a Food object.

         - Parameters:
            - foodID (String): The FatSecret food ID to look up.
            - completion (Optional Food): A closure called with the parsed Food object, or nil if the request fails.
         */

        fetchAccessToken { token in
            guard let safeToken = token else {
                completion(nil)
                return
            }

            let urlString = "https://platform.fatsecret.com/rest/food/v4?food_id=\(foodID)&format=json"

            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(safeToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let safeData = data else {
                    completion(nil)
                    return
                }

                let food = self.parseFoodDetail(data: safeData)
                completion(food)
            }
            task.resume()
        }
    }


    func findFoodByBarcode(barcode: String, completion: @escaping (Food?) -> Void) {
        /**
         Looks up a food item by its barcode using the FatSecret API. The barcode endpoint returns the same
         response structure as the food detail endpoint, so parseFoodDetail is reused.

         - Parameters:
            - barcode (String): A 13-digit GTIN-13 barcode string.
            - completion (Optional Food): A closure called with the parsed Food object, or nil if not found.
         */

        fetchAccessToken { token in
            guard let safeToken = token else {
                completion(nil)
                return
            }

            let urlString = "https://platform.fatsecret.com/rest/food/barcode/find-by-id/v2?barcode=\(barcode)&format=json"

            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(safeToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("[FatSecret] Barcode error: \(error)")
                    completion(nil)
                    return
                }
                guard let safeData = data else {
                    print("[FatSecret] Barcode: no data")
                    completion(nil)
                    return
                }

                let food = self.parseFoodDetail(data: safeData)
                completion(food)
            }
            task.resume()
        }
    }


    func parseFoodDetail(data: Data) -> Food? {
        /**
         Parses JSON data from the FatSecret API into a Food object with measures.

         - Parameters:
            - data (Data): The raw data retrieved from the API.

         - Returns: An Optional Food object parsed from the JSON.
         */

        do {
            let decoded = try JSONDecoder().decode(FSFoodDetailResponse.self, from: data)
            let foodDetail = decoded.food
            let servings = foodDetail.servings.serving

            guard let firstServing = servings.first else { return nil }

            let foodName = foodDetail.food_name.lowercased()
            let brandName = (foodDetail.brand_name ?? "unbranded").lowercased()

            // Build measures from all servings
            var measures: [Measure] = []
            var defaultMeasure: Measure?

            for serving in servings {
                guard let metricAmountStr = serving.metric_serving_amount,
                      let metricAmount = Double(metricAmountStr),
                      metricAmount > 0 else { continue }

                let expression = "\(serving.number_of_units) \(serving.measurement_description)".lowercased()
                let measure = Measure(measureExpression: expression, measureMass: metricAmount)
                measures.append(measure)

                if defaultMeasure == nil {
                    defaultMeasure = measure
                }
            }

            // Fallback if no measures were created
            if measures.isEmpty {
                return nil
            }

            let selectedMeasure = defaultMeasure ?? measures[0]

            // Calculate protein per gram from the first serving with metric data
            let proteinValue = Double(firstServing.protein) ?? 0.0
            let metricAmount = Double(firstServing.metric_serving_amount ?? "0") ?? 0.0
            let proteinPerGram = metricAmount > 0 ? proteinValue / metricAmount : 0.0

            return Food(
                food: foodName,
                proteinPerGram: proteinPerGram,
                brandName: brandName,
                measures: measures,
                selectedMeasure: selectedMeasure,
                multiplier: 1.0,
                consumptionTime: nil
            )
        } catch {
            return nil
        }
    }
}
