/**
 TabBarController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the tab bar
 History:
 Mar 18, 2025: File creation
*/

import Foundation
import UIKit

class TabBarController: UITabBarController {
    /**
     A class that allows the Tab Bar Controller to be hidden and shown.
     */
    
    
    override func viewWillAppear(_ animated: Bool) {
        /**
         Called just before the Tab Bar Controller is loaded and overrides the default behaviour to hide the Tab Bar Controller.
         
         - Parameters:
            - animated (Bool): Indicates if the appearance is animated.
         */
        
        super.viewWillAppear(animated)
        
        // Hide navigation button upon completing authentication
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

