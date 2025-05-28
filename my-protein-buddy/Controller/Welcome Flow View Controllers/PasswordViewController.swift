/**
 PasswordViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the password components of the log in
 History:
 Mar 18, 2025: File creation
*/

import UIKit
import Firebase

class PasswordViewController: UIViewController {
    /**
     A class that allows the user to reset their password in the Password View Controller.
     
     - Properties:
       - email (Optional String): Contains the user's email address from the previous View Controller.
       - emailTextField (Unwrapped UITextField): Displays the user's email and allows the user to edit their email address.
     */
    
    let alertManager = AlertManager()
    var email: String? = ""
    
    @IBOutlet weak var emailTextField: UITextField!
    
    
    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded and displays the user's email address on the screen.
         */
        
        super.viewDidLoad()
        
        // Set email text field text as email
        emailTextField.text = email
    }
    
    
    @IBAction func sendEmailPressed(_ sender: UIButton) {
        /**
         Sends a password reset email to the address currently entered in the text box.
         
         - Parameters:
            - sender (UIButton): Triggers the password-reset email to be sent.
         */
        
        // Code from https://firebase.google.com/docs/auth/ios/manage-users
        
        // If email is not nil
        if let email = emailTextField.text {
            
            // Send password reset email if email is not nil. sendPasswordReset has email validation
            Auth.auth().sendPasswordReset(withEmail: email) { err in
                
                // If there is an error, show error to user
                if let err = err {
                    self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                }
                
                // Otherwise, fetch sign in methods to use to reset password
                else {
                    Auth.auth().fetchSignInMethods(forEmail: email, completion: {
                        (signInMethods, err) in
                        
                        // If there is an error, show error to user
                        if let err = err {
                            self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                        }
                        
                        // Otherwise, notify user to check their email
                        else {
                            self.alertManager.showAlert(alertMessage: "please check your email to reset your password", viewController: self) {
                                
                                // Return to welcome view controller if email is sent
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                    )
                }
            }
        }
    }
}
