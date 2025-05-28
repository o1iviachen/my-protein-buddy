/**
 SelectorViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the manual protein goal selector
 History:
 Mar 26, 2025: File creation
*/

import UIKit
import Firebase

class SelectorViewController: UIViewController {
    /**
     A class that allows the user to select and set a daily protein goal using a UI Slider in the Selector View Controller, saving this data to Firebase Firestore once the user confirms their input.
     
     - Properties:
        - proteinLabel (Unwrapped UILabel): Displays the user's protein goal.
        - proteinSlider (Unwrapped UISlider): Allows the user to use a slider to set their daily protein goal.
     */
    
    let db = Firestore.firestore()
    let firebaseManager = FirebaseManager()
    let alertManager = AlertManager()
    var proteinAmount = 0

    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var proteinSlider: UISlider!
    
    
    @IBAction func proteinChanged(_ sender: UISlider) {
        /**
         Updates the text when the user adjusts their protein goal.
         
         - Parameters:
            - sender (UISlider): Contains the updates protein goal to be displayed.
         */
        
        proteinLabel.text = "\(Int(sender.value)) g"
    }
    
    
    @IBAction func confirmPressed(_ sender: UIButton) {
        /**
         Saves the updated protein goal to the user's document in Firebase Firestone once the user confirms their input.
         
         - Parameters:
            - sender (UIButton): Triggers the confirmation and data storage flow.
         */
        
        proteinAmount = Int(proteinSlider.value)
        
        // Save selected protein amount to user document on Firebase Firestore
        firebaseManager.setProteinGoal(proteinAmount: proteinAmount)
        alertManager.showAlert(alertMessage: "your protein goal is now \(proteinAmount) g. you can change this at any time on the profile page", viewController: self) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

