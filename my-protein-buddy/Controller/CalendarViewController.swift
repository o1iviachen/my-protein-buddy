/**
 CalendarViewController.swift
 my-protein-buddy
 Emily, Olivia, and Su
 This file runs calendar components
 History:
 Mar 26, 2025: File creation
 Apr 4, 2025: Added segues between the calendar and logged foods
*/

import SwiftUI
import UIKit
import Foundation

// Source: https://www.youtube.com/watch?v=B_VFHeg2LH4&t=7s
// Generates a Calendar View for users to easily access and view their past food logs
class CalendarViewController: UIViewController {
    /**
     A class that allows the Calendar View Controller to set up and display a SwiftUI calendar inside a UIKit Storyboard.
     */

    
    override func viewDidLoad() {
        /**
         Called after the View Controller is loaded and sets up the SwiftUI Calendar.
         */
        
        super.viewDidLoad()
        setupSwiftUICalendar()
    }

    
    private func setupSwiftUICalendar() {
        /**
         Creates and adds the CalendarUI inside the current Calendar View Controller.
         */
        
        let calendarScene = CalendarScene()

        // Adds the Calendar View as a child view controller to link it to the StoryBoard
        let hostingController = UIHostingController(rootView: calendarScene)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}


struct CalendarScene: View {
    /**
     A structure for the SwiftUI view that displays a calendar interface and allows the user to select a date, then display the Food View Controller with the food log for the selected date.
     */
    
    @State private var selectedDate: Date? = nil
    @State private var navigate = false

    var body: some View {
        // Allows the CalendarUI to be navigated
        NavigationStack {
            // Custom functionality that allows and records the user's date selection
            VStack {
                CalendarView(canSelect: true, selectedDate: $selectedDate)
                    .scaledToFit()
                    .onChange(of: selectedDate) { newDate in
                        if newDate != nil {
                            navigate = true
                        }
                    }
                Spacer()
                Spacer()
                // Triggers the FoodView for the user's selected date to be displayed
                NavigationLink(
                    destination: Group {
                        if let date = selectedDate {
                            FoodView(date: date)
                        }
                    },
                    isActive: $navigate,
                    label: { EmptyView() }
                )
            }
            .padding(.horizontal)
            .background(Color(red: 255/255, green: 240/255, blue: 219/255))
        }
    }
}


struct CalendarScene_Previews: PreviewProvider {
    /**
     A structure that allows previews of the CalendarUI during development.
     */
    static var previews: some View {
        CalendarScene()
    }
}


struct CalendarView: UIViewRepresentable {
    /**
     A structure that creates a SwiftUI view to link the UIKit Storyboard and SwiftUI, allowing the date selection functionality to work.
     */
    
    // The calendar system to use
    var calendarIdentifier: Calendar.Identifier = .gregorian
    // Whether date selection is enabled
    var canSelect: Bool = false
    // A variable to store the selected date
    @Binding var selectedDate: Date?

    
    func makeCoordinator() -> CalendarCoordinator {
        /**
         Creates and returns a coordinator to manage interactions and event selections between the SwiftUI and Storyboard.
         
         - Returns: A CalendarCoordinator instance that is used as a delegate.
         */
        
        CalendarCoordinator(calendarIdentifier: calendarIdentifier, canSelect: canSelect, selectedDate: $selectedDate)
    }
  
    
    func makeUIView(context: Context) -> UICalendarView {
        /**
         Creates and sets up Storyboard Calendar View, and links the coordinator to the Calendar View.
         
         - Parameters:
            - context (Context): Contains the coordinator information.
         
         - Returns: A configured UICalendarView instance.
         */
        
        let view = UICalendarView()
        // Set the calendar system
        view.calendar = Calendar(identifier: calendarIdentifier)
    
        // Enable selection behavior if canSelect is true
        if canSelect {
            view.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        }
    
        // Assign the coordinator as the delegate
        view.delegate = context.coordinator
        return view
    }
  
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        /**
         Updates the Storyboard Calendar View when the SwiftUI state changes.
         
         - Parameters:
            - uiView (UICalendarView): Indicates the existing view that is to be updated.
            - context (Context): Containes the coordinator and state information.
         */
        
        let calendar = Calendar(identifier: calendarIdentifier)
        uiView.calendar = calendar
        context.coordinator.calendarIdentifier = calendarIdentifier
    
        // If selection is disabled, highlight the previously selected date
        if !canSelect, let selectedDate {
            var components = Set<DateComponents>()
            // Store the previously selected date (if any)
            if let previousDate = context.coordinator.pickedDate {
            components.insert(calendar.dateComponents([.month, .day, .year], from: previousDate))
            }
            // Store the newly selected date
            components.insert(calendar.dateComponents([.month, .day, .year], from: selectedDate))
            // Update the picked date in the coordinator
            context.coordinator.pickedDate = selectedDate
            // Refresh the calendar view to apply decorations
            uiView.reloadDecorations(forDateComponents: Array(components), animated: true)
        }
    }
}


final class CalendarCoordinator: NSObject, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
    /**
     A class that behaves as the delegate for date selection. Updates the range of selectable dates and stores the last picked date for UI embellishments.

     */
    var calendarIdentifier: Calendar.Identifier
    let canSelect: Bool

    // Variable to update the selected date in SwiftUI
    @Binding var selectedDate: Date?
    var pickedDate: Date? // Stores the most recently selected date
    // Computed property to get the calendar instance
    var calendar: Calendar {
        Calendar(identifier: calendarIdentifier)
    }
  
    
    init(calendarIdentifier: Calendar.Identifier, canSelect: Bool, selectedDate: Binding<Date?>) {
        /**
         Initialises the coordinator with required properties and configurations.
         
         - Parameters:
            - calendarIdentifier (Calendar.Identifier): Indicates the calendar system.
            - canSelect (Bool): Indicates if date selection is enabled
            - selectedDate (Binding<Date?>): Allows the current selected date to be readable and writable.
         */
        
        self.calendarIdentifier = calendarIdentifier
        self.canSelect = canSelect
        self._selectedDate = selectedDate
    }
  
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                     didSelectDate dateComponents: DateComponents?) {
        /**
         Updates the selectedDate binding with the chosen date from the calendar.
         
         - Parameters:
            - selection (UICalendarSelectionSingleDate): Indicates the selection behaviour.
            - dateComponents (DateComponents?): Contains the selected date components from the calendar.
         */
        
        guard
            let dateComponents,
            let date = calendar.date(from: dateComponents)
        else { return }
        self.selectedDate = date // Update the SwiftUI state with the selected date
    }
}
