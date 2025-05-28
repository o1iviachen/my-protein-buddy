/**
 CalculatorViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the protein goal calculator
 History:
 Mar 26, 2025: File creation
 Apr 78 2025: Updated protein goal calculations logic
*/

import UIKit
import Firebase

class CalculatorViewController: UIViewController {
    var backButtonShow: Bool = false
    let db = Firestore.firestore()
    let alertManager = AlertManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the back button visibility based on backButtonShow
        navigationItem.hidesBackButton = !backButtonShow
    }
    
    @IBOutlet weak var heightSlider: UISlider!
    @IBOutlet weak var activitySlider: UISlider!
    @IBOutlet weak var weightSlider: UISlider!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    
    @IBAction func heightChanged(_ sender: UISlider) {
        heightLabel.text = "\(String(format: "%.2f", sender.value)) m"
    }
    
    @IBAction func weightChanged(_ sender: UISlider) {
        weightLabel.text = "\(Int(sender.value)) kg"
    }
    
    
    @IBAction func activityChanged(_ sender: UISlider) {
        switch sender.value {
        case 0.0..<0.33:
            activityLabel.text = "less active"
        case 0.33..<0.66:
            activityLabel.text = "moderately active"
        case 0.66...1.0:
            activityLabel.text = "very active"
        default:
            activityLabel.text = "active"
        }
    }
    
    
    @IBAction func calculateGoal(_ sender: UIButton) {
        
        // Get all values for calculation
        let activity = activitySlider.value
        let height = heightSlider.value
        let weight = weightSlider.value
        var proteinGoal = 0
        let bmiValue = Double(weight) / Double(height * height)
        if bmiValue < 24.9 {
            switch activity {
            case 0.0..<0.25:
                proteinGoal = Int(weight*2.2*0.8)
            case 0.25..<0.75:
                proteinGoal = Int(weight*2.2*1.0)
            case 0.75...1.0:
                proteinGoal = Int(weight*2.2*1.2)
            default:
                proteinGoal = 0
            }
        } else if bmiValue >= 24.9 {
            switch activity {
            case 0.0..<0.33:
                proteinGoal = Int(height*100)
            case 0.33..<0.66:
                proteinGoal = Int(weight*2.2*1.0)
            case 0.66...1.0:
                proteinGoal = Int(weight*2.2*1.2)
            default:
                proteinGoal = 0
            }
        }
        
        
        db.collection("users").document((Auth.auth().currentUser?.email)!).setData(["proteinGoal": proteinGoal], merge: true)
        
        alertManager.showAlert(alertMessage: "your protein goal is now \(proteinGoal) g. you can change this at any time on the profile page", viewController: self) {
            // Make sure there is two or more view controllers
            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                
                // If the last view controller is a profile view controller, the use did not just sign up. Therefore, pop view controller to profile view controller
                if viewController is ProfileViewController {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    
                    // Otherwise, go to tam bar controller as user is using the application for the first time
                    self.performSegue(withIdentifier: K.calculatorTabSegue, sender: self)
                }
            }
        }
    }
}

