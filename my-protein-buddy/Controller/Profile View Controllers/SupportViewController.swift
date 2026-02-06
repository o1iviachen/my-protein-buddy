/**
 SupportViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the email support component
 History:
 Mar 26, 2025: File creation
*/

import UIKit
import MessageUI
import Firebase


class SupportViewController: UIViewController {
    /**
     A class that allows the Support View Controller to compose and send support emails within the app. Includes functionality for the user to write messages and minimise the keyboard when appropriate based on the user's actions.
     
     - Properties:
        - viewHolder (Unwrapped UIView): Provides styling and layout contraints for the UI Text View.
        - textView (Unwrapped UITextView): Displays the text.
     */
    
    let alertManager = AlertManager()
    
    @IBOutlet weak var viewHolder: UIView!
    @IBOutlet weak var textView: UITextView!
    
    
    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded to set up the UI Text View for user input.
         */
        
        // Round corner of view holding text view; code from https://stackoverflow.com/questions/1509547/giving-uiview-rounded-corners
        viewHolder.layer.cornerRadius = 10;
        viewHolder.layer.masksToBounds = true;
        
        // Keyboard goes down when screen is tapped outside and swipped
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        /**
         Validates the user's text input and send the email.
         
         - Parameters:
            - sender (UIButton): Triggers the email to be sent.
         */
        
        // Send the email; if the email is empty, notify the user
        if textView.text == "" {
            self.alertManager.showAlert(alertMessage: "email body is empty.", viewController: self)
            return
        }
        sendEmail(body: textView.text, controller: self)
    }
    
    
    @objc func handleSwipe() {
        /**
         Dimisses the keyboard when the user swipes downwards.
         */
        
        textView.resignFirstResponder()
    }
    
    
    @objc func handleTap() {
        /**
         Dismisses the keyboard when the user taps outside of the Text Field.
         */
        
        textView.resignFirstResponder()
    }
}

//MARK: - MFMailComposeViewControllerDelegate
extension SupportViewController: MFMailComposeViewControllerDelegate {
    /**
     An extension that uses a pre-filled email composer to handle the user's email actions.
     */
    
    
    func sendEmail(body: String, controller: SupportViewController) {
        /**
         Displays a pre-filled email composer for the user to send an email, after checking if the user's device is configured to send emails.
         
         - Parameters:
            - body (String): Contains the content to be sent in the email.
            - controller (SupportViewController): Presents the mail composer.
         */
        
        // Code from https://stackoverflow.com/questions/65743004/swiftui-send-email-using-mfmailcomposeviewcontroller
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()

            // Prepare email to be sent
            mailComposer.mailComposeDelegate = controller
            if let userEmail = Auth.auth().currentUser?.email {
                mailComposer.setPreferredSendingEmailAddress(userEmail)
            }
            mailComposer.setToRecipients(["olivia63chen@gmail.com"])
            mailComposer.setSubject("inquiry about my-protein-buddy.")
            mailComposer.setMessageBody("\(body)", isHTML: false)
            controller.present(mailComposer, animated: true, completion: nil)
        }
        
        // Show error if email was not prepared
        else {
            self.alertManager.showAlert(alertMessage: "unable to send email.", viewController: self)
        }
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        /**
         Communicates to the user the result of the email composition attempt.
         
         - Parameters:
            - controller (MFMailComposeViewController): Indicates the controller that was used.
            - result (MFMailComposeResult): Indicates the status of the email attempt.
            - error (Optional Error): Indicates if any issue has occured.
         */
        
        switch result {
            
        // Notify email result to user using a pop-up unless cancelled
        case .sent:
            controller.dismiss(animated: true, completion: {
                self.alertManager.showAlert(alertMessage: "email sent!", viewController: self)
            })
        case .saved:
            controller.dismiss(animated: true, completion: {
                self.alertManager.showAlert(alertMessage: "email saved!", viewController: self)
            })
        case .cancelled:
            controller.dismiss(animated: true, completion: nil)
            
        case .failed:
            controller.dismiss(animated: true, completion: {
                self.alertManager.showAlert(alertMessage: "the email was not sent.", viewController: self)
            })
        @unknown default:
            break
        }
        
    }
}


