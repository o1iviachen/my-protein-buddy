//
//  ViewController.swift
//  figology-v2
//
//  Created by olivia chen on 2025-02-25.
//

import UIKit

class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openFatSecret(_ sender: UIButton) {
        if let url = URL(string: "https://www.fatsecret.com") {
            UIApplication.shared.open(url)
        }
    }


}

