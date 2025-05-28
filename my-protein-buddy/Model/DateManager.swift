/**
 DateManager.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs the date functionalities
 History:
 Apr 27, 2025: File creation
 Apr 27, 2025: Increased modularity of date functionalities
 Apr 27, 2025: Added branded foods
*/

import Foundation

struct DateManager {
    /**
     A structure to manage the date format between String and Date types.
     */

    let dateFormatter = DateFormatter()
    
    init() {
        /**
         Initialises a new instance of DateManager with a consistent date format.
         */
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }
    
    func formatCurrentDate(dateFormat: String) -> String {
        /**
         Returns the current date and time in the specified format.
         
         - Parameters:
            - dateFormat (String): Represents the target date format (yy_MM_dd HH:mm:ss).
         
         - Returns: The current date converted to the specific dateFormat.
         */
        
        // Get the current date and time
        let date = Date()
        
        // Set formatter style to chosen format
        dateFormatter.dateFormat = dateFormat
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func formatString(dateString: String, stringFormat: String) -> Date {
        /**
         Returns the date String as a Date object.
         
         - Parameters:
            - dateString (String): Contains the date in the specified dateFormat.
            - dateFormat (String): Represents the current date format (yy_MM_dd HH:mm:ss).
         
         - Returns: A Date object parsed from the String.
         */
        
        // Set formatter style to chosen format
        dateFormatter.dateFormat = stringFormat
        let date = dateFormatter.date(from: dateString)!
        return date
    }
}
