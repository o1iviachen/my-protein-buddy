/**
 LogInViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the log in components
 History:
 Mar 7, 2025: File creation
 Mar 7, 2025: Added Google log in
 Mar 18, 2025: Added email and password log in
*/

import UIKit
import GoogleSignIn
import Firebase
import AuthenticationServices
import CryptoKit


class LogInViewController: UIViewController {
    /**
     A class that allows the View Controller to manage the user log-in and subsequent navigation, compatible with email/password, Google Sign-In, and Sign in with Apple.

     - Properties:
        - passwordTextField (Unwrapped UITextField): Allows the user to enter their password.
        - emailTextField (Unwrapped UITextFIeld): Allows the user to enter their email address.
        - currentNonce (Optional String): Stores the nonce used for Apple Sign-In security.
     */

    let db = Firestore.firestore()
    let alertManager = AlertManager()
    var currentNonce: String?

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!


    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.configuration?.image = UIImage(systemName: imageName)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /**
         Passes the user's email address before the user navigates to the password screen.
         
         - Parameters:
            - segue (UIStoryboardSegue): Indicates the View Controllers involved in the segue.
            - sender (Optional Any): Indicates the object that initiated the segue.
         */
                
        // If segue that will be performed goes to password view controller
        if segue.identifier == K.logInPasswordSegue {
            
            // Force downcast destinationVC as PasswordViewController
            let destinationVC = segue.destination as! PasswordViewController
            
            // Set PasswordViewController class attribute as user's email, if typed
            if let email = emailTextField.text {
                destinationVC.email = email
            }
        }
    }
    
    
    @IBAction func loginPressed(_ sender: UIButton) {
        /**
         Allows the user to log-in using their email and password, and performs the appropriate segue if the attempt is successful.
         
         - Parameters:
            - sender (UIButton): Triggers the log-in.
         */
        
        // Code from https://firebase.google.com/docs/auth/ios/password-auth

        // If email and password are not nil
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            // Sign in user using email and password. signIn has email and password validation
            Auth.auth().signIn(withEmail: email, password: password) { authResult, err in
                
                // If there is an error, show error to user
                if let err = err {
                    
                    // Unless the "error" is the user cancelling the authentication
                    if err.localizedDescription != "The user canceled the sign-in flow." {
                        self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                    }
                    
                // Otherwise, perform segue to tab bar view controller
                } else {
                    self.performSegue(withIdentifier: K.logInTabSegue, sender: self)
                }
            }
        }
    }
    
    
    @IBAction func appleLogInPressed(_ sender: UIButton) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }


    @IBAction func googleLogInPressed(_ sender: GIDSignInButton) {
        /**
         Allows the user to log-in using Google Sign-In, and performs the appropriate segue if the attempt is successful.
         
         - Parameters:
            - sender (GIDSignInButton): Triggers Google Sign-In.
         */
        
        // Code from https://firebase.google.com/docs/auth/ios/google-signin
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
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
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken!, accessToken: user!.accessToken.tokenString)
                    
                    // Sign in user with Google
                    Auth.auth().signIn(with: credential) { result, err in
                        
                        // If there are errors in signing in, show error to user
                        if let err = err {
                            self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                        }
                        
                        // Otherwise, check if user is new or not
                        else {
                            
                            if let isNewUser: Bool = result?.additionalUserInfo?.isNewUser {
                                
                                // If user is new, go to calculator view controller
                                if isNewUser {
                                    self.performSegue(withIdentifier: K.logInCalculatorSegue, sender: self)
                                }
                                
                                // If user is not new, go to tab bar view controller
                                else {
                                    self.performSegue(withIdentifier: K.logInTabSegue, sender: self)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Sign in with Apple

extension LogInViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else { return }
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                alertManager.showAlert(alertMessage: "Unable to fetch identity token.", viewController: self)
                return
            }

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)

            Auth.auth().signIn(with: credential) { result, err in
                if let err = err {
                    self.alertManager.showAlert(alertMessage: err.localizedDescription, viewController: self)
                } else {
                    if let isNewUser = result?.additionalUserInfo?.isNewUser {
                        if isNewUser {
                            self.performSegue(withIdentifier: K.logInCalculatorSegue, sender: self)
                        } else {
                            self.performSegue(withIdentifier: K.logInTabSegue, sender: self)
                        }
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
            alertManager.showAlert(alertMessage: error.localizedDescription, viewController: self)
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

