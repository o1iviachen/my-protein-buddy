/**
 ProfileCell.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file initialises the profile class
 History:
 Mar 26, 2025: File creation
*/

import UIKit

class ProfileCell: UITableViewCell {
    /**
     A custom UITableViewCell subclass that displays the user's profile information.
     
     - Properties:
        - label (Unwrapped UILabel): Displays text.
        - iconImage (Unwrapped UIImageView): Displays an icon image.
     */

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    
}
