/**
 SignUpViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the sign up components
 History:
 Mar 7, 2025: File creation
 Mar 14, 2025: Fixed Google authentication flow
*/

import UIKit
import GoogleSignIn
import Firebase


class SignUpViewController: UIViewController {
    /**
     A class that allows the View Controller to manage the user sign-up, compatible with email/password registration and Google Sign-In. It also uses Firebase Authentication to create new accounts, handle errors, and guide the app navigation.
     
     - Properties:
        - passwordTextField (Unwrapped UITextField): Allows the user to enter their password.
        - emailTextField (Unwrapped UITextFIeld): Allows the user to enter their email address.
     */
    
    let db = Firestore.firestore()
    let alertManager = AlertManager()
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    
    @IBAction func signUpPressed(_ sender: UIButton) {
        /**
         Attempts to create a new user with the entered email and password, and navigates the user to the appropriate View Controller.
         
         - Parameters:
            - sender (UIButton): Triggers the sign-up.
         */
        
        // Code from https://firebase.google.com/docs/auth/ios/password-auth
        
        // If email and password are not nil
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            // Create new user using email and password. createUser has email and password validation
            Auth.auth().createUser(withEmail: email, password: password) { authResult, err in
                
                // If there is an error, show error to user
                if let err = err {
                    
                    // Unless the "error" is the user cancelling the authentication
                    if err.localizedDescription != "The user canceled the sign-in flow." {
                        self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                    }
                    
                // Otherwise, perform segue to calculator
                } else {
                    self.performSegue(withIdentifier: K.signUpCalculatorSegue, sender: self)
                }
            }
        }
    }
    
    
    @IBAction func googleSignUpPressed(_ sender: GIDSignInButton) {
        /**
         Initiates Google Sign-In to authenticate the user, and navigates the user to the appropriate View Controller.
         
         - Parameters:
            - sender (GIDSignInButton): Triggers Google Sign-In.
         */
        
        // Code from https://firebase.google.com/docs/auth/ios/google-signin
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start sign in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, err in
            
            // If there is an error, show error to user
            if let err = err {
                
                // Unless the "error" is the user cancelling the authentication
                if err.localizedDescription != "The user canceled the sign-in flow." {
                    self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                }
                
            } else {
                if (result?.user) != nil {
                    let user = result?.user
                    let idToken = user?.idToken?.tokenString
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken!,
                                                                   accessToken: user!.accessToken.tokenString)
                    
                    // Sign in user with Google
                    Auth.auth().signIn(with: credential) { result, err in
                        
                        // If there are errors in signing up, show error to user
                        if let err = err {
                            self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                            
                        }
                        
                        // Otherwise, check if user is new or not
                        else {
                            
                            if let isNewUser: Bool = result?.additionalUserInfo?.isNewUser {
                                
                                // If user is new, go to calculator view controller
                                if isNewUser {
                                    self.performSegue(withIdentifier: K.signUpCalculatorSegue, sender: self)
                                }
                                
                                // If user is not new, go to tab bar view controller
                                else {
                                    self.performSegue(withIdentifier: K.signUpTabSegue, sender: self)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

