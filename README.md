# README

## Name
MyProteinBuddy is a protein-tracking application.

## Features
- Facilitates authentication using email and password or Google accounts.
- Allows users to input their protein goal or calculate their protein goal based on their age, height, weight, and activity level.
- Allows users to log, edit, and delete their intake of various foods, from which their protein intake is calculated. 
- Organises and displays protein intake by meal, including historical data. 

## Installation
This version of the application is only supported by macOS devices. 

### Installing the required software 
Xcode and CocoaPods need to be installed to run this application. 
If these are already installed, skip this section. 
1. Install Xcode from the App Store. 
2. Open the Terminal and install CocoaPods by entering ``brew install cocoapods``.

### Cloning and running MyProteinBuddy
1. Open Xcode and select **Clone Git Repository**. 
2. Enter the [repository link](https://github.com/o1iviachen/my-protein-buddy.git) and select **Clone**.
3. Select a location to save the cloned repository and select **Clone** to complete the cloning process.
4. Go to the Project File icon at the top of the Project Navigator (left-side panel) and change the Bundle Identifier. Apple recommends the following format: ``com.[your-organization-or-name].[app-name]``.
5. Log in to [Firebase](https://firebase.google.com/) and go to console.
6. Create a Firebase project. At the following screen, select the iOS+ icon. Only follow the shown steps 1 and 2, but click through all steps to reach the Project page. Ensure to use your Bundle Identifier as the Apple bundle ID and the newly added property list is exactly titled "GoogleService-Info.plist."
7. On the left-side panel, click the Build dropdown and select Authentication.
   - Add Email/Password and Google as authentication methods.
   - Click the Build dropdown again and select Firebase Database.
   - Create a new Cloud Firestore database.
8. To install CocoaPods dependencies, open the Terminal and navigate to the folder containing the cloned repository using ``cd`` and the file's entire pathway.
   This terminal command may look like ``cd /Users/su/Desktop/my-protein-buddy``. Then, enter ``pod install``. From now on, only open the new .xcworkspace file.
9. Create a new Configuration Settings File in the project folder titled "Secrets."
   - Create your Nutritionix API Key and ID at [Nutritionix](https://developer.nutritionix.com/signup) and store them as variables named ``NUTRITIONIX_APP_KEY`` and ``NUTRITIONIX_APP_ID``.
   - Go to the GoogleService-Info.plist, copy the value belonging to the ``REVERSED_CLIENT_ID`` key and store it as a variable named ``GOOGLE_URL_SCHEME``.
   - The file should now look like the following:
      - ```
        NUTRITIONIX_APP_KEY = <YOUR_APP_KEY>
        NUTRITIONIX_APP_ID = <YOUR_APP_ID>
        GOOGLE_URL_SCHEME = <YOUR_URL_SCHEME>
        ```
10. Go to the Project File icon and click the Project, not the Targets. Go to the Info tab. Under Configurations, select both dropdowns for Debug and Release. For both configurations, select "None" and change the field to "Secrets."
11. In Xcode, click the Run button or press ``Cmd + R`` to run MyProteinBuddy 

## Known Bugs
After signing up, users will not be directed to the calculator page automatically. 
However, users should direct themselves to this page to set their protein goal. 
This bug does not hinder the application's functionality. 

## Support
Contact olivia63chen@gmail.com directly or through the support page on MyProteinBuddy if help is required. 
