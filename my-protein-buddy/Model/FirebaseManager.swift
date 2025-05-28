/**
 FirebaseManager.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file updates the database
 History:
 Apr 2, 2025: File creation
 Apr 16, 2025: Implemented completion handler
 Apr 17, 2025: Removed code redundancy
*/

import Foundation
import Firebase

struct FirebaseManager {
    /**
     A structure that manages the food and protein logging with Firebase, including fetching, adding, updating, and removing food entries in the user's daily logs stored in Firebase Firestore.
     */
    
    let db = Firestore.firestore()
    
    
    func fetchUserDocument(completion: @escaping (DocumentSnapshot?) -> Void) {
        /**
         Fetches a Firebase Firestore document authorized through the user's email.
         
         - Parameters:
            - completion (Optional DocumentSnapshot): Stores the Firebase Firestore information at the time of the call.
         */
        
        db.collection("users").document((Auth.auth().currentUser?.email)!).getDocument { document, error in
            
            // If an error occurs in fetching document, call completion handler with no document snapshot (nil); code from https://cloud.google.com/firestore/docs/manage-data/add-data
            guard let document = document else {
                completion(document)
                return
            }
            
            // If the document is empty, call completion handler with no document snapshot (nil)
            guard document.data() != nil else {
                completion(document)
                return
            }
            
            completion(document)
        }
    }
    
    
    func logFood(food: Food, meal: String, dateString: String, proteinIntake: Double, completion: @escaping (Bool) -> Void) {
        /**
         Logs the protein from the user's food input to the user's daily protein intake.
         
         - Parameters:
            - food (Food): Food object with identification, protein, and consumption information.
            - meal (String): The meal during which the food was consumed.
            - dateString (String): The date (yy_MM_dd HH:mm:ss) the food was logged.
            - proteinIntake (Double): The current daily total protein intake.
            - completion (Bool):  Indicates if the Firebase Firestore update was successful.
         */
        
        // Add food's protein to the user's daily protein intake; learned that arguments in Swift are immutable https://stackoverflow.com/questions/40268619/why-are-function-parameters-immutable-in-swift
        let changedIntake = proteinIntake + food.proteinPerGram*food.selectedMeasure.measureMass*food.multiplier
        
        let encoder = JSONEncoder()
        do {
            
            // Encode Food object to log food to Firebase Firestore
            let foodData = try encoder.encode(food)
            if let foodDictionary = try JSONSerialization.jsonObject(with: foodData, options: []) as? [String: Any] {
                
                // Add corresponding food dictionary and changed protein intake to user's document in Firebase Firestore; code from https://cloud.google.com/firestore/docs/manage-data/add-data
                db.collection("users").document((Auth.auth().currentUser?.email)!).setData([
                    dateString: [meal: FieldValue.arrayUnion([foodDictionary]), "proteinIntake": changedIntake]
                ], merge: true) { err in
                    
                    // If no error occurs in logging food, call completion handler with success (true)
                    if err == nil {
                        completion(true)
                    }
                    
                    // Otherwise, call completion handler with failure (false)
                    else {
                        completion(false)
                    }
                }
            }
        }
        
        // If an error occurs in encoding, call completion handler with failure (false)
        catch {
            completion(false)
        }
    }
    
    
    func removeFood(food: Food, meal: String, dateString: String, proteinIntake: Double, completion: @escaping (Bool) -> Void) {
        /**
         Removes the food item and associated protein measurement from the user's log.
         
         - Parameters:
            - food (Food): Food object with identification, protein, and consumption information.
            - meal (String): The meal during which the food was consumed.
            - dateString (String): The date (yy_MM_dd HH:mm:ss) the food was logged.
            - proteinIntake (Double): The current daily total protein intake.
            - completion (Bool):  Indicates if the Firebase Firestore update was successful.
         */
        
        // Subtract food's protein from user's daily protein intake; learned that arguments in Swift are immutable https://stackoverflow.com/questions/40268619/why-are-function-parameters-immutable-in-swift
        let changedIntake = proteinIntake - food.proteinPerGram*food.selectedMeasure.measureMass*food.multiplier
                
        let encoder = JSONEncoder()
        do {
            
            // Encode Food object to remove food from Firebase Firestore
            let foodData = try encoder.encode(food)
            if let foodDictionary = try JSONSerialization.jsonObject(with: foodData, options: []) as? [String: Any] {
                
                // Remove corresponding food dictionary and add changed protein intake (absolute value to account for -0.0 calculations) to user's document in Firebase Firestore; code from https://cloud.google.com/firestore/docs/manage-data/add-data
                db.collection("users").document((Auth.auth().currentUser?.email)!).setData([
                    dateString: [meal: FieldValue.arrayRemove([foodDictionary]), "proteinIntake": abs(changedIntake)]
                ], merge: true) { err in
                    
                    // If no error occurs in removing food, call completion handler with success (true)
                    if err == nil {
                        completion(true)
                    }
                    
                    // Otherwise, call completion handler with failure (false)
                    else {
                        completion(false)
                    }
                }
            }
        }
        
        // If an error occurs in encoding, call completion handler with failure (false)
        catch {
            completion(false)
        }
    }
    
    
    func fetchRecentFoods(document: DocumentSnapshot?, completion: @escaping ([Food]) -> Void) {
        /**
         Fetches and organizes the recent food logs chronologically.
         
         - Parameters:
            - document (Optional DocumentSnapshot): Stores the Firebase Firestore information at the time of the call.
            - completion ([Food]): A sorted array with the Food logs from most recent to least recent.
         */
        
        var recentData: [Food] = []
        
        // Unwrap document data recent foods and optional downcast to list of dictionaries
        if let safeData = document?.data()?["recentFoods"] as? [[String: Any]] {
            
            // Loop through the recent foods to create corresponding Food objects
            for food in safeData {
                let foodObject = parseFirebaseFood(food: food)
                
                // Append Food object to recent data list
                recentData.append(foodObject)
            }
            
            let dateManager = DateManager()
            
            // Sort the foods from latest to earliest using bubble sort
            for i in 0..<recentData.count - 1 {
                var swapped = false
                
                // Check each consumption time against next consumption time
                for j in 0..<recentData.count-i-1 {
                    
                    // If the current consumption time is earlier than the next consumption time, swap the two elements
                    if dateManager.formatString(dateString: recentData[j].consumptionTime!, stringFormat: "yy_MM_dd HH:mm:ss") < dateManager.formatString(dateString: recentData[j+1].consumptionTime!, stringFormat: "yy_MM_dd HH:mm:ss") {
                        swapped = true
                        recentData.swapAt(j, j+1)
                    }
                }
                
                // If nothing swaps after an iteration, the foods are already sorted
                if !swapped {
                    completion(recentData)
                }
            }
        }
        completion(recentData)
    }
    
    
    func addToRecentFoods(food: Food, recentFoods: [Food]) {
        /**
         Stores the user's food input.
         
         - Parameters:
            - food (Food): Food object with identification, protein, and consumption information.
            - recentFoods ([Food]): An array containing a maximum of the 10 most recent foods.
         */
        
        let encoder = JSONEncoder()
        
        // Limit recent foods list to 10 foods
        if recentFoods.count == 10 {
            do {
                
                // Encode earliest Food object to remove food from Firebase Firestore; code from https://cloud.google.com/firestore/docs/manage-data/add-data
                let foodtoDeleteData = try encoder.encode(recentFoods[9])
                if let foodtoDeleteDictionary = try JSONSerialization.jsonObject(with: foodtoDeleteData, options: []) as? [String: Any] {
                    
                    // Remove corresponding food dictionary from recent foods in user's document in Firebase Firestore
                    db.collection("users").document((Auth.auth().currentUser?.email)!).setData([
                        "recentFoods": FieldValue.arrayRemove([foodtoDeleteDictionary])
                    ], merge: true, completion: nil)
                }
            } catch {}
        }
        
        do {
            
            // Encode Food object to add food to Firebase Firestore
            let foodData = try encoder.encode(food)
            if let foodDictionary = try JSONSerialization.jsonObject(with: foodData, options: []) as? [String: Any] {
                
                // Add corresponding food dictionary to user's document in Firebase Firestore; code from https://cloud.google.com/firestore/docs/manage-data/add-data
                db.collection("users").document((Auth.auth().currentUser?.email)!).setData([
                    "recentFoods": FieldValue.arrayUnion([foodDictionary])], merge: true, completion: nil)
            }
        } catch {}
    }
    
    
    func fetchFoods(dateString: String, document: DocumentSnapshot?, completion: @escaping ([[Food]]) -> Void) {
        /**
         Fetches the stored food items and prepares them for UI display.
         
         - Parameters:
            - dateString (String): The date (yy_MM_dd HH:mm:ss) the food was logged.
            - document (Optional DocumentSnapshot): Stores the Firebase Firestore information at the time of the call.
            - completion ([[Food]]): A sorted array with the Food logs grouped by meal type.
         */
        
        var tableData: [[Food]] = [[],[],[],[]]
        let mealNames = ["breakfast", "lunch", "dinner", "snacks"]
        
        // Unwrap document data for the requested date and optional downcast to dictionary
        if let safeData = document?.data()?[dateString] as? [String: Any] {
            for meal in mealNames {
                
                // Optional downcast each meal to array of dictionaries
                if let foods = safeData[meal] as? [[String: Any]] {
                    
                    // Loop through the logged foods in each meal to initialise Food objects
                    for food in foods {
                        let foodObject = parseFirebaseFood(food: food)
                        
                        // Append Food object to table data, index of nested array depends on meal
                        tableData[mealNames.firstIndex(of: meal)!].append(foodObject)
                    }
                }
            }
        }
        
        // Call completion handler once all data is fetched
        completion(tableData)
    }
    
    
    func fetchProteinIntake(dateString: String, document: DocumentSnapshot?, completion: @escaping (Double) -> Void) {
        /**
         Fetches the protein intake for the stored food items and prepares the data for UI display.
         
         - Parameters:
            - dateString (String): The date (yy_MM_dd HH:mm:ss) the food was logged.
            - document (Optional DocumentSnapshot): Stores the Firebase Firestore information at the time of the call.
            - completion (Double): Stores the total protein intake for that day.
         */
        
        var proteinIntake: Double = 0.0
        
        // Unwrap document data for the requested date and optional downcast to dictionary
        if let currentDate = document?.data()?[dateString] as? [String: Any] {
            
            // If protein intake exists, assign it to proteinIntake with two decimal places
            if let currentProteinIntake = currentDate["proteinIntake"] {
                proteinIntake = ((currentProteinIntake as! Double)*10).rounded() / 10
            }
        }
        
        // Call completion handler possibly with protein intake
        completion(proteinIntake)
    }
    
    func setProteinGoal(proteinAmount: Int) {
        db.collection("users").document((Auth.auth().currentUser?.email)!).setData([ "proteinGoal": proteinAmount], merge: true)
    }
    
    func fetchProteinGoal(document: DocumentSnapshot?, completion: @escaping (Int?) -> Void) {
        /**
         Fetches the user's protein goal.
         
         - Parameters:
            - document (Optional DocumentSnapshot): Stores the Firebase Firestore information at the time of the call.
            - completion (Optional Int): Stores the user's daily protein goal.
         */
        
        // Fetch protein goal, which may be nil
        let proteinGoal = document?.data()?["proteinGoal"] as? Int
        
        // Call completion handler possibly with protein goal
        completion(proteinGoal)
    }
    
    
    func parseFirebaseFood(food: [String: Any]) -> Food {
        /**
         Parses and converts a dictionary from Firebase Firestore into a Food object.
         
         - Parameters:
            - food (Dictionary): Represents a single food entry in Firebase.
        
         - Returns: A Food object created from the Firebase Firestore dictionary.
         */
        
        var measurements: [Measure] = []
        
        // Force downcast the food's measures to array of dictionaries since a food must have measures
        let retrievedMeasures = food["measures"] as! [[String: Any]]
        for measurement in retrievedMeasures {
            
            // Create Measure object using Firebase Firestore data
            let measureExpression = measurement["measureExpression"] as! String
            let measureMass = measurement["measureMass"] as! Double
            let measureObject = Measure(measureExpression: measureExpression, measureMass: measureMass)
            measurements.append(measureObject)
        }
        
        // Create selected measure dictionary by forced downcast since measure must be selected for food to be logged
        let selectedMeasure = food["selectedMeasure"] as! [String: Any]
        
        // Create Food object
        let foodObject = Food(
            food: food["food"] as! String,
            proteinPerGram: food["proteinPerGram"] as! Double, brandName: food["brandName"] as! String,
            measures: measurements, selectedMeasure: Measure(measureExpression: selectedMeasure["measureExpression"] as! String, measureMass: selectedMeasure["measureMass"] as! Double), multiplier: food["multiplier"] as! Double, consumptionTime: food["consumptionTime"] as? String
        )
        
        return(foodObject)
    }
}
