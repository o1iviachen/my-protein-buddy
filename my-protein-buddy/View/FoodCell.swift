/**
 FoodCell.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file initialises the food class
 History:
 Mar 24, 2025: File creation
*/

import UIKit

class FoodCell: UITableViewCell {
    /**
     A custom UITableViewCell subclass that displays information about a food item.
     
     - Properties:
        - foodNameLabel (Unwrapped UILabel): Displays the name of the food item.
        - foodDescriptionLabel (Unwrapped UILabel): Displays a description or brand name of the food item.
        - proteinMassLabel (Unwrapped UILabel): Displays the protein mass of the food item.
     */

    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var foodDescriptionLabel: UILabel!
    @IBOutlet weak var proteinMassLabel: UILabel!
    
}
