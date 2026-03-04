/**
 CalculatorViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the protein goal calculator
 History:
 Mar 26, 2025: File creation
 Apr 78 2025: Updated protein goal calculations logic
 Mar 2026: Replaced activity-based formula with evidence-based BMI formula; added citations
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
    @IBOutlet weak var weightSlider: UISlider!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!

    @IBAction func heightChanged(_ sender: UISlider) {
        heightLabel.text = "\(String(format: "%.2f", sender.value)) m"
    }

    @IBAction func weightChanged(_ sender: UISlider) {
        weightLabel.text = "\(Int(sender.value)) kg"
    }


    @IBAction func calculateGoal(_ sender: UIButton) {

        let height = heightSlider.value
        let weight = weightSlider.value
        let bmiValue = Double(weight) / Double(height * height)
        var proteinGoal = 0

        if bmiValue < 18.5 {
            // Underweight: higher protein to support weight gain
            proteinGoal = Int(Double(weight) * 1.5)
        } else if bmiValue < 25.0 {
            // Normal weight
            proteinGoal = Int(Double(weight) * 1.2)
        } else {
            // Overweight/Obese: cap adjusted body weight at BMI 30
            let adjustedWeight = min(Double(weight), 30.0 * Double(height) * Double(height))
            proteinGoal = Int(adjustedWeight * 1.2)
        }


        db.collection("users").document((Auth.auth().currentUser?.email)!).setData(["proteinGoal": proteinGoal], merge: true)

        alertManager.showAlert(alertMessage: "your protein goal is now \(proteinGoal) g. you can change this at any time on the profile page", viewController: self) {
            // Make sure there is two or more view controllers
            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                let viewController = navController.viewControllers[navController.viewControllers.count - 2]

                // If the last view controller is a profile view controller, the user did not just sign up. Therefore, pop view controller to profile view controller
                if viewController is ProfileViewController {
                    self.navigationController?.popViewController(animated: true)
                } else {

                    // Otherwise, go to tab bar controller as user is using the application for the first time
                    self.performSegue(withIdentifier: K.calculatorTabSegue, sender: self)
                }
            }
        }
    }


    @IBAction func openSources(_ sender: UIButton) {
        let alert = UIAlertController(title: "sources", message: "protein recommendations are based on peer-reviewed research:", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "issn position stand: protein and exercise", style: .default) { _ in
            UIApplication.shared.open(URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/")!)
        })

        alert.addAction(UIAlertAction(title: "harvard health: how much protein do you need?", style: .default) { _ in
            UIApplication.shared.open(URL(string: "https://www.health.harvard.edu/blog/how-much-protein-do-you-need-every-day-201506188096")!)
        })

        alert.addAction(UIAlertAction(title: "protein requirement in obesity (2024)", style: .default) { _ in
            UIApplication.shared.open(URL(string: "https://pubmed.ncbi.nlm.nih.gov/39514335/")!)
        })

        alert.addAction(UIAlertAction(title: "close", style: .cancel))

        // iPad support for action sheet
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }
}
