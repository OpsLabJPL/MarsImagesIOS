//
//  LeftDrawerViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit

class LeftDrawerViewController : UIViewController {
    
    @IBOutlet weak var leftDrawerButton: ArrowButton!
    @IBOutlet weak var leftDrawerLeadingConstraint: NSLayoutConstraint!
    var leftDrawerHidden = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func leftDrawerButtonPressed(_ sender: Any) {
        if leftDrawerHidden {
            UIView.animate(withDuration: 0.5, animations: {
                self.leftDrawerLeadingConstraint.constant = 0
                self.view.layoutIfNeeded()
                self.leftDrawerButton.leftDirection = true
            })
        }
        else {
            UIView.animate(withDuration: 0.5, animations: {
                self.leftDrawerLeadingConstraint.constant = -240
                self.view.layoutIfNeeded()
                self.leftDrawerButton.leftDirection = false
            })
        }
        leftDrawerHidden = !leftDrawerHidden
    }

    
}
