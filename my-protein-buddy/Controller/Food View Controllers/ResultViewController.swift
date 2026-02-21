/**
 ResultViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file updates the UI after food logging
 History:
 Apr 2, 2025: File creation
*/

import UIKit
import Firebase
import SwiftUI

class ResultViewController: UIViewController {
    /**
     A class that allows the Results View Controller to display the details for the food items. It also allows the user to log their specific food intake, and trakcs the user's progress towards their daily protein intake goal.
     
     - Properties:
        - foodLabel (Unwrapped UILabel): Displays the name of the food item.
        - proteinLabel (Unwrapped UILabel): Shows the calculated protein content of the specific amount of food logged.
        - progressBar (Unwrapped UIProgressView): Visually indicates the percent of protein intake goal achieved.
        - descriptionLabel (Unwrapped UILabel): Displays additional information about the food item.
        - progressLabel (Unwrapped UILabel): Shows the user's daily protein consumption progress relative to their goal.
        - servingTextField (Unwrapped UITextField): Allows the user to enter the quantity of food consumed.
        - servingMeasureButton (Unwrapped UIButton): Allows the user to select a unit of measurement.
        - mealButton (Unwrapped UIButton): Allows the user to select a meal category.
     */
    
    let firebaseManager = FirebaseManager()
    let alertManager = AlertManager()
    let dateManager = DateManager()
    let db = Firestore.firestore()
    var rawPickerOptions: [Any] = []
    var measureQuantity = 0.0
    var proteinMass = 0.0
    var measureList: [Measure] = []
    var selectedFood: Food? = nil
    var temporaryMeasure: Measure? = nil
    var proteinIntake: Double = 0.0
    var measureDescriptionList: [String] = []
    var dateString: String? = nil
    var originalMeal: String = "breakfast"
    var proteinGoal: Int? = nil
    
    @IBOutlet weak var foodLabel: UILabel!
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var servingTextField: UITextField!
    @IBOutlet weak var servingMeasureButton: UIButton!
    @IBOutlet weak var mealButton: UIButton!
    @IBOutlet weak var loadingAnimation: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded and displays the relevant food details from Firebase.
         */
        
        super.viewDidLoad()
        
        servingMeasureButton.setTitleColor(UIColor(red: 102/255, green: 51/255, blue: 0/255, alpha: 1), for: .normal)

        // Set self as the serving text field's delegate to manage user interaction
        servingTextField.delegate = self
        
        // Initially configure UI with unmodified food
        mealButton.setTitle(originalMeal, for: .normal)
        servingTextField.text = String(selectedFood!.multiplier)
        
        // Set temporary measure (keep selected food unchanged in case user is updating)
        temporaryMeasure = selectedFood!.selectedMeasure
        
        // Set date string
        dateString = dateManager.formatCurrentDate(dateFormat: "yy_MM_dd")

        // Show loading animation
        loadingAnimation.isHidden = false

        // Fetch user document
        firebaseManager.fetchUserDocument { document in

            // Use DispatchGroup to wait for all fetches to complete before updating UI
            let dispatchGroup = DispatchGroup()

            // Fetch protein goal
            dispatchGroup.enter()
            self.firebaseManager.fetchProteinGoal(document: document) { fetchedGoal in
                if let setProteinGoal = fetchedGoal {
                    self.proteinGoal = setProteinGoal
                }
                dispatchGroup.leave()
            }

            // Fetch protein intake
            dispatchGroup.enter()
            self.firebaseManager.fetchProteinIntake(dateString: self.dateString!, document: document) { proteinIntake in
                self.proteinIntake = proteinIntake
                dispatchGroup.leave()
            }

            // Update UI only after all fetches complete
            dispatchGroup.notify(queue: .main) {
                self.loadingAnimation.isHidden = true
                self.updateUI()
            }
        }
        
        // Picker goes down when screen is tapped outside and swipped
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }

    @IBAction func openFatSecret(_ sender: UIButton) {
        if let url = URL(string: "https://www.fatsecret.com") {
            UIApplication.shared.open(url)
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /**
         Passes data to the Picker View Controller in preparation for this segue.
         
         - Parameters:
            - segue (UIStoryboardSegue): Indicates the View Controllers involved in the segue.
            - sender (Optional Any): Indicates the object that initiated the segue.
         */
        
        // If segue is to picker view controller
        if segue.identifier == K.resultPickerSegue {
            let destinationVC = segue.destination as! PickerViewController
            
            // Set self as the picker view controller's delegate to manage user interaction
            destinationVC.delegate = self
            
            // Determine the picker options depending on the selected button
            destinationVC.options = rawPickerOptions
        }
    }
    
    
    @objc func handleSwipe() {
        /**
         Dimisses the keyboard and refreshes the UI when the user swipes downwards.
         */
        
        updateUI()
        servingTextField.resignFirstResponder()
    }
    
    
    @objc func handleTap() {
        /**
         Dismisses the keyboard and refreshes the UI when the user taps outside of the Text Field.
         */
        
        updateUI()
        servingTextField.resignFirstResponder()
    }
    
    
    @IBAction func mealButtonSelected(_ sender: UIButton) {
        /**
         Prepares the meal selector and performs the segue.
         
         - Parameters:
            - sender (UIButton): Triggers the meal selection flow.
         */
        
        rawPickerOptions = ["breakfast", "lunch", "dinner", "snacks"]
        performSegue(withIdentifier: K.resultPickerSegue, sender: self)
    }
    
    
    @IBAction func servingButtonSelected(_ sender: UIButton) {
        /**
         Prepares the measurement picker and performs the segue.
         
         - Parameters:
            - sender (UIButton): Triggers the serving measure flow.
         */
        
        rawPickerOptions = selectedFood!.measures
        performSegue(withIdentifier: K.resultPickerSegue, sender: self)
    }
    
    
    @IBAction func addFood(_ sender: UIBarButtonItem) {
        /**
         Logs the newly added food item to Firebase, updates the array of recent foods, and navigates to the previous View Controller.

         - Parameters:
            - sender (UIBarButtonItem): Indicates that the user has confirmed their entry and triggers the updates for adding a food item.
         */

        // Validate required data before proceeding
        if let multiplierText = servingTextField.text,
           let multiplier = Double(multiplierText),
           let measure = temporaryMeasure,
           let date = dateString {

            // Check if UIHostingController is in navigation stack
            let exists = navigationController?.viewControllers.contains {
                $0 is UIHostingController<AnyView>
            } == true

            // If previous view controller is a FoodViewController, the user was updating their food; code from https://stackoverflow.com/questions/16608536/how-to-get-the-previous-viewcontroller-that-pushed-my-current-view
            if let navController = self.navigationController, navController.viewControllers.count >= 2 || exists {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                print(viewController)
                if viewController is FoodViewController || viewController is UIHostingController<AnyView>{

                    // Therefore, remove the original selected food
                    if let food = selectedFood {
                        firebaseManager.removeFood(food: food, meal: originalMeal, dateString: date, proteinIntake: proteinIntake) { foodRemoved in

                            // Communicate error to user
                            if !foodRemoved {
                                self.alertManager.showAlert(alertMessage: "could not remove previous food.", viewController: self)
                            }
                        }
                    }
                }
            }

            // Modify selected food to new values
            self.selectedFood?.multiplier = multiplier
            self.selectedFood?.selectedMeasure = measure

            // Get current time to distinguish duplicate foods as Firebase's arrayUnion function will not save duplicate entries https://cloud.google.com/firestore/docs/manage-data/add-data ; code from https://stackoverflow.com/questions/24070450/how-to-get-the-current-time-as-datetime
            self.selectedFood?.consumptionTime = dateManager.formatCurrentDate(dateFormat: "yy_MM_dd HH:mm:ss")

            // Fetch user document
            firebaseManager.fetchUserDocument { document in

                // Add new modified food to user's recent foods
                if let food = self.selectedFood {
                    self.firebaseManager.fetchRecentFoods(document: document) { recentFoods in
                        self.firebaseManager.addToRecentFoods(food: food, recentFoods: recentFoods)
                    }

                    // Fetch protein intake
                    self.firebaseManager.fetchProteinIntake(dateString: date, document: document) { newIntake in

                        // Log new modified food
                        if let meal = self.mealButton.currentTitle {
                            self.firebaseManager.logFood(food: food, meal: meal, dateString: date, proteinIntake: newIntake) { foodAdded in

                                // If food was not logged, communicate error to user
                                if !foodAdded {
                                    self.alertManager.showAlert(alertMessage: "could not add new food.", viewController: self)
                                }

                                // Otherwise, return to previous view controller
                                else {
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            alertManager.showAlert(alertMessage: "invalid input.", viewController: self)
        }
    }
    
    
    func updateUI() {
        /**
         Updates the Results View Controller with the selected food's information, including updating the protein quantity and progress.
         */

        // Safely unwrap required values
        if let food = selectedFood,
           let measure = temporaryMeasure,
           let multiplierText = servingTextField.text,
           let multiplier = Double(multiplierText) {

            // Calculate protein in consumed food
            let calculatedProtein = food.proteinPerGram * measure.measureMass * multiplier

            // Update UI with inputted values
            foodLabel.text = food.food
            proteinLabel.text = "\(String(format: "%.1f", calculatedProtein)) g"
            descriptionLabel.text = "\(food.brandName), \(String(format: "%.1f", measure.measureMass * multiplier)) g"

            // Truncate text button if measure expression length is greater than 9
            if measure.measureExpression.count < 10 {
                servingMeasureButton.setTitle(measure.measureExpression, for: .normal)
            } else {
                servingMeasureButton.setTitle("\(String(measure.measureExpression.prefix(9)))...", for: .normal)
            }

            // If protein goal is not nil, calculate the percent of the daily goal the food accounts for
            if let safeProteinGoal = proteinGoal {
                let progressPercent = calculatedProtein / Double(safeProteinGoal)
                progressLabel.text = "this is \(Int(progressPercent * 100))% of your protein goal!"
                progressBar.progress = Float(progressPercent)
                progressBar.isHidden = false
            }

            // Otherwise, tell user to set their protein goal
            else {
                progressLabel.text = "please set your protein goal."
                progressBar.isHidden = true
            }
        }
    }
}

//MARK: - PickerViewControllerDelegate
extension ResultViewController: PickerViewControllerDelegate {
    /**
     An extension that processes the data that is to be displayed in the Picker View Controller and updates the UI to reflect these choices.
     */
    
    
    func didSelectValue(value: Any) {
        /**
         Updates the UI depending on if the user wishes to update the meal or serving measure.
         
         - Parameters:
            - value (Any): Contains the value selected by the user, either a String of the meal or a Measure object for the serving size unit.
         */
        
        // If the value is a string, it is a meal title
        if value is String {
            
            // Therefore, change the meal button text
            mealButton.setTitle(value as? String, for: .normal)
        }
        
        // Otherwise, it is a Measure
        else {
            
            // Hold new selected measure as temporary measure, to keep selected food the same
            temporaryMeasure = value as? Measure
            updateUI()
        }
    }
}

//MARK: - UITextFieldDelegate
extension ResultViewController: UITextFieldDelegate {
    /**
     An extension that validates the user's serving size input.
     */
    
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        /**
         Validates the user's input in the Text Field when the user finishes editing their input.
         
         - Parameters:
            - textField (UITextField): Allows the user to enter their desired serving.
         
         - Returns: A Bool indicating if the current Text Field is valid and the user can stop editing.
         */
        
        // If serving text field is empty or is not a number when user tries to stop editing, write 1 as placeholder value
        if Double(textField.text ?? "empty") != nil {
            return true
        } else {
            textField.text = "1"
            return false
        }
    }
}
