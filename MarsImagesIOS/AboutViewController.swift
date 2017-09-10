//
//  AboutViewController.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/9/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit

class AboutViewController : UIViewController {
    
    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string:"https://s3.amazonaws.com/www.powellware.net/MarsImagesiOS.html")!
        self.webview.loadRequest(URLRequest(url: url))
    }
}
