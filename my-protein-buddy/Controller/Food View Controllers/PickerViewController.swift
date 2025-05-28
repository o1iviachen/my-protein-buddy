/**
 PickerViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file delegates the information from the user's picked foods
 History:
 Apr 3, 2025: File creation
*/

import UIKit

protocol PickerViewControllerDelegate: AnyObject {
    /**
     A protocol that sends the value from the Picker View Controller to another class.
     */
    
    
    func didSelectValue(value: Any)
        /**
         Notifies the delegate about the user's selection from the Picker View Controller.
         
         - Parameters:
            - value (Any): Contains the value the user selected with the picker.
         */
}

class PickerViewController: UIViewController {
    /**
     A class that allows the Picker View Controller to present a list of options for the user to select from, and communicates the user's interaction with the picker.
     
     - Properties:
        - informationPicker (Unwrapped UIPickerView): Displays the choice options on the picker.
     */
    
    weak var delegate: PickerViewControllerDelegate?
    var options: [Any] = []
    var modifiedOptions: [String] = []
    
    @IBOutlet weak var informationPicker: UIPickerView!
    
    
    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded to set up the Picker View Controller's delegate and data source, and prepares the display options.
         */
        
        super.viewDidLoad()
        
        // Set self as the information picker's delegate to handle user interactions
        informationPicker.delegate = self
        
        // Set self as the information picker's delegate to provide the data
        informationPicker.dataSource = self
        
        // Modify height of picker to 50% of the screen; code from https://stackoverflow.com/questions/68107275/swift-5-present-viewcontroller-half-way
        if let sheet = self.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        
        // If the options are strings (meal titles), let the information picker options be the unmodified options
        if let checkedOptions = options as? [String] {
            modifiedOptions = checkedOptions
        }
        
        // Otherwise, the options are Measures; therefore, make the information picker options be the measures' measure expressions
        else {
            modifiedOptions = options.map { ($0 as! Measure).measureExpression }
        }
    }
}

//MARK: - UIPickerViewDelegate
extension PickerViewController: UIPickerViewDelegate {
    /**
     An extension that allows the Picker View Controller to respond to the user's interactions with the picker.
     */
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        /**
         Returns the displayed text for each option in the picker.
         
         - Parameters:
            - pickerView (UIPickerView): Requests the information.
            - row (Int): Indicates the index of the row.
            - component (Int): Indicates the column index of the component.
         
         - Returns: An optional String with the title for each row in the picker.
         */
        
        // Provides text to display for a given row in the picker
        return modifiedOptions[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        /**
         Indicates the specific option from the picker the user selected.
         
         - Parameters:
            - pickerView (UIPickerView): Notifies the delegate that the user made a selection.
            - row (Int): Indicates the index of the selected row.
            - component (Int): Indicates the column index of the selected row.
         */
        
        // Gets selected value from unmodified options
        let selectedValue = options[row]
        
        // Allow delegate to perform action with selected value
        delegate?.didSelectValue(value: selectedValue)
    }
    
}

//MARK: - UIPickerViewDataSource
extension PickerViewController: UIPickerViewDataSource {
    /**
     An extension that provides the picker with a format to display the list of options.
     */
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        /**
         Returns the number fo columns for the picker view.
         
         - Parameters:
            - pickerView (UIPickerView): Requests this information.
         
         - Returns: An Int indicating the number of columns needed.
         */
        
        // Returns the number of columns in a picker view
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        /**
         Returns the number of rows in each picker view column.
         
         - Parameters:
            - pickerView (UIPickerView): Requests this information.
            - component (Int): Indicates the number of rows in each column.
         
         - Returns: An Int indicating the number of rows needed.
         */
        
        // Returns the number of rows in a picker view
        return modifiedOptions.count
    }
}
