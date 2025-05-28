/**
 ErrorManager.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the app alerts
 History:
 Apr 7, 2025: File creation
*/

import UIKit

struct AlertManager {
    /**
     A structure to manage and present alert pop-ups across different view controllers in the app.
     */
    
    
    func showAlert(alertMessage: String, viewController: UIViewController, onDismiss: (() -> Void)? = nil) {
        /**
         Presents an alert dialog with a customizable message on the specified view controller.
         
         - Parameters:
            - alertMessage (String): Contains the customised message to be displayed in the alert.
            - viewController (UIViewController): Name of the view controller where the alert should be displayed.
            - onDismiss (Optional Closure): Specific action that may be executed once the alert is dismissed.
         */
        
        // Create alert with message argument
        let alert = UIAlertController(title: "alert", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        
        // Add dismiss option that can call a chosen function
        alert.addAction(UIAlertAction(title: "dismiss", style: UIAlertAction.Style.default, handler: { _ in onDismiss?()
        }))
        
        // Present alert on chosen view controller
        viewController.present(alert, animated: true, completion: nil)
    }
}
