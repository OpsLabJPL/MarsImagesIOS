//
//  LeftDrawerViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit

class LeftDrawerViewController : UIViewController {
    
    @IBOutlet weak var leftDrawerLeadingConstraint: NSLayoutConstraint!
    var leftDrawerHidden = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(openDrawer), name: .openDrawer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeDrawer), name: .closeDrawer, object: nil)
    }
    
    @IBAction func leftDrawerButtonPressed(_ sender: Any) {
        if leftDrawerHidden {
            openDrawer()
        }
        else {
            closeDrawer()
        }
        leftDrawerHidden = !leftDrawerHidden
    }

    @objc func openDrawer() {
        UIView.animate(withDuration: 0.5, animations: {
            self.leftDrawerLeadingConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func closeDrawer() {
        UIView.animate(withDuration: 0.5, animations: {
            self.leftDrawerLeadingConstraint.constant = -240
            self.view.layoutIfNeeded()
        })
    }
    
}
