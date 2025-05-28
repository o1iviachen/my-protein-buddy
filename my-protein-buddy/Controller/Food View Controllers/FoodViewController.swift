/**
 FoodViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file retrieves the user's logged food
 History:
 Mar 5, 2025: File creation
*/

import Foundation
import UIKit
import Firebase
import SwiftUI

class FoodViewController: UIViewController {
    /**
     A class that allows the Food View Controller to manage the user's food intake and protein consumption, and display the data in a table grouped by meals. It also allows the user to edit and delete food entries with Firebase.
     
     - Properties:
        - tableViewHeightConstraint (Unwrapped NSLayoutConstraint): Dynamically adjusts the height of the Table View.
        - tableView (Unwrapped UITableView): Displays food items grouped by meal.
        - progressLabel (Unwrapped UILabel): Shows the user's daily protein consumption progress relative to their goal.
        - progressBar (Unwrapped UIProgressView): Visually indicates the percent of protein intake goal achieved.
     */
    
    let firebaseManager = FirebaseManager()
    let alertManager = AlertManager()
    let dateManager = DateManager()
    let headerTitles = ["breakfast", "lunch", "dinner", "snacks"]
    var exists = false
    var dateString: String? = nil
    var proteinRequests: [URLRequest?] = []
    var proteinGoal: Int? = nil
    var tableData: [[Food]] = []
    var proteinIntake = 0.0
    var selectedFood: Food? = nil
    var selectedMeal: String? = nil
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded and displays the custom food cells.
         */
        
        super.viewDidLoad()
        
        // Set self as the table view's delegate to handle user interactions
        tableView.delegate = self

        // Set self as the table view's data source to provide the data
        tableView.dataSource = self

        // Register food cell in table view
        tableView.register(UINib(nibName: K.foodCellIdentifier, bundle: nil), forCellReuseIdentifier: K.foodCellIdentifier)
        
        // Start with progress bar hidden
        progressBar.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        /**
         Called just before the View Controller is loaded and adjusts the View Controller based on the user's desires.
         
         - Parameters:
            - animated (Bool): Indicates if the appearance is animated.
         */
        
        super.viewWillAppear(animated)
        
        // If the date string is nil, set the date as today; a non-nil date string signifies the food view controller was instantiated from the calendar view controller
        if dateString == nil {
            dateString = dateManager.formatCurrentDate(dateFormat: "yy_MM_dd")
        }
        
        // Fetch user document in Firebase Firestore; code from https://firebase.google.com/docs/firestore/query-data/get-data
        firebaseManager.fetchUserDocument { document in
            
            // Fetch current date's consumed foods and populate table view with foods
            self.firebaseManager.fetchFoods(dateString: self.dateString!, document: document) { data in
                self.tableData = data
                self.tableView.reloadData()
            }
            
            // Fetch current date's current protein intake
            self.firebaseManager.fetchProteinIntake(dateString: self.dateString!, document: document) { intake in
                self.proteinIntake = Double(intake)
            }
            
            // Fetch protein goal and update progress UI
            self.firebaseManager.fetchProteinGoal(document: document) { goal in
                self.proteinGoal = goal
                self.updateProgressUI()
            }
        }
        
        // Change the table view height depending on the number of foods
        DispatchQueue.main.async {
            if CGFloat(62*self.tableData.joined().count + 40) > self.tableView.bounds.size.height {
                self.tableViewHeightConstraint.constant = CGFloat(62*self.tableData.joined().count + 40)
                self.tableView.reloadData()
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /**
         Prepares data before a segue to the Result View Controller is performed to pass the selected food and its meal category to the destination.
         
         - Parameters:
            - segue (UIStoryboardSegue): Indicates the View Controllers involved in the segue.
            - sender (Optional Any): Indicates the object that initiated the segue.
         */
        
        // If the segue to be performed goes to the result view controller (the food is being edited)
        if segue.identifier == K.foodResultSegue {
            let destinationVC = segue.destination as! ResultViewController
            
            // Prepare the result view controller's attributes
            destinationVC.selectedFood = selectedFood!
            destinationVC.originalMeal = selectedMeal!
        }
    }
    
    
    func updateProgressUI() {
        /**
         Updates the progress label and progress bar based on the user's protein intake and tells the user to set their protein goal if not already done.
         */
        
        // If protein goal is not nil
        if let setProteinGoal = proteinGoal {
            
            // Update progress label
            self.progressLabel.text = "you have consumed \(self.proteinIntake) g out of your \(setProteinGoal) g protein goal! way to go."
            
            // Show decimal progress on progress bar
            self.progressBar.progress = Float(self.proteinIntake/Double(setProteinGoal))
            self.progressBar.isHidden = false
        }
        
        // If protein goal is nil
        else {
            
            // Communicate to user to set their protein goal
            self.progressLabel.text = "please set your protein goal."
        }
    }
}

//MARK: - UITableViewDataSource
extension FoodViewController: UITableViewDataSource {
    /**
     An extension that configures a list of foods to be grouped and displayed by meal type, defining the table properties and the contents of each food cell.
     */
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        /**
         Determines the number of sections to display in the table view.
         
         - Parameters:
            - tableView (UITableView): Requests this information.

         - Returns: An Int representing the number of meal categories.
         */
        
        // Required to populate the correct number of sections (number of meal types)
        return tableData.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /**
         Returns the number of food entries in a specific meal section.
         
         - Parameters:
            - tableView (UITableView): Requests this information.
            - section (Int): Indicates the index of the section requesting its row count.
         
         - Returns: An Int representing the number of food items for the specified meal.
         */
        
        // Required to populate the correct number of foods per meal
        return tableData[section].count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /**
         Configures and returns a Table View Cell with the food name, brand, mass consumed, and protein content.
         
         - Parameters:
            - tableView (UITableView): Requests this information.
            - indexPath (IndexPath): Specifies the section and row of the cell.
         
         - Returns: A UITableView Cell populated with the appropriate format.
         */
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.foodCellIdentifier, for: indexPath) as! FoodCell
        
        // Get the required Food object
        let cellFood = tableData[indexPath.section][indexPath.row]
        
        // Access the Food object's attributes to customise the cell accordingly
        cell.foodNameLabel.text = cellFood.food
        
        // Calculate the consumed mass
        let descriptionString = "\(cellFood.brandName), \(String(format: "%.1f", cellFood.multiplier*cellFood.selectedMeasure.measureMass)) g"
        cell.foodDescriptionLabel.text = descriptionString
        
        // Calculate the protein mass for the consumed mass
        cell.proteinMassLabel.text = "\(String(format: "%.1f", cellFood.proteinPerGram*cellFood.multiplier*cellFood.selectedMeasure.measureMass)) g"
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        /**
         Provides the title for a given section in the Table View.
         
         - Parameters:
            - tableView (UITableView): Requests this information.
            - section (Int): Indicates the index of the section requesting its header title.
         
         - Returns: An Unwrapped String containing the title for the specific section or nil if the title is unavailable.
         */
        
        // As long as there are more header titles, continue naming the sections
        if section < headerTitles.count {
            return headerTitles[section]
        }
        return nil
    }
}

//MARK: - UITableViewDelegate
extension FoodViewController: UITableViewDelegate {
    /**
     An extension that handles user interactions with the Table View, including responding to the user selecting food items and swiping entries to delete food entries from both the UI and Firebase.
     */
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /**
         Redirects the user to an editing screen when trying to edit the current day's food log.

         - Parameters:
            - tableView (UITableView): Indicates the row selection.
            - indexPath (IndexPath): Specifies the selected row.
         */
        
        // Check if UIHostingController is in navigation stack
        exists = navigationController?.viewControllers.contains {
            $0 is UIHostingController<AnyView>
        } == true

        // If not, user is not checking the food view controller from the calendar view controller. Therefore, allow user to edit food
        if !exists {
            selectedMeal = headerTitles[indexPath.section]
            selectedFood = tableData[indexPath.section][indexPath.row]
            performSegue(withIdentifier: K.foodResultSegue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        /**
         Determines if user can edit a food cell

         - Parameters:
            - tableView (UITableView): Indicates the row selection.
            - indexPath (IndexPath): Specifies the selected row.
         */
        
        // Check if UIHostingController is in navigation stack
        exists = navigationController?.viewControllers.contains {
            $0 is UIHostingController<AnyView>
        } == true
        
        return !exists
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        /**
         Allows the user to swipe to delete food items from Firebase, before updating the Table View UI and the progress bar.
         
         - Parameters:
            - tableView (UITableView): Indicates the row selection.
            - editingStyle (UITableViewCell.EditingStyle): Indicates the editing action.
            - indexPath (IndexPath): Specifies which row will be edited.
         */
        
        // Makes editing style the delete style upon swiping left; code from https://stackoverflow.com/questions/24103069/add-swipe-to-delete-uitableviewcell
        if editingStyle == .delete {
            
            // Get the food to delete
            selectedFood = tableData[indexPath.section][indexPath.row]
            
            // Delete food from Firebase Firestore
            firebaseManager.removeFood(food: selectedFood!, meal: headerTitles[indexPath.section], dateString: dateString!, proteinIntake: proteinIntake) { foodRemoved in
                
                // If food is successfully removed
                if foodRemoved {
                    
                    // Remove food from the table data
                    self.tableData[indexPath.section].remove(at: indexPath.row)
                    
                    // Delete food from table view with fade animation (self.tableView.reloadData() would not have the fade)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    // Fetch user document
                    self.firebaseManager.fetchUserDocument { document in
                        
                        // Fetch protein intake with food removal
                        self.firebaseManager.fetchProteinIntake(dateString: self.dateString!, document: document) { intake in
                            self.proteinIntake = intake
                            
                            // Upon completion, update progress UI
                            self.updateProgressUI()
                        }
                    }
                    
                // Otherwise, show error to user
                } else {
                    self.alertManager.showAlert(alertMessage: "could not remove food.", viewController: self)
                }
            }
        }
    }
}

//MARK: - UIViewControllerRepresentable
struct FoodView: UIViewControllerRepresentable {
    /**
     A structure that allows the Food View Controller to be used with SwiftUI views by passing a date to the controller.
     */
    
    let date: Date

    
    func updateUIViewController(_ uiViewController: FoodViewController, context: Context) {
        /**
         A required function that is not currently used.
         
         - Parameters:
            - uiViewController (FoodViewController): Indicates the View Vontroller instance to update.
            - context (Context): Provides information for updating the View Controller.
         */
    }
       
    
    func makeUIViewController(context: Context) -> FoodViewController {
        /**
         Creates and instance and configures a FoodViewController from the Storyboard with a given date. .
         
         - Parameters:
            - context (Context): Provides information for creating the View Controller.
         
         - Returns: An instance of a configured FoodViewController.
         */
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FoodViewController") as! FoodViewController
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy_MM_dd"
        vc.dateString = dateFormatter.string(from: date)
        return vc
    }
}
