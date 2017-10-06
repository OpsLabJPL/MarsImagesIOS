//
//  InternetReachabilityStatus.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/4/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SwiftMessages

class InternetReachabilityStatus {
    static func createStatus(_ layout: MessageView.Layout = .statusLine) -> MessageView {
        let status = MessageView.viewFromNib(layout: layout)
        status.button?.isHidden = true
        status.iconLabel?.text = "❌"
        status.iconImageView?.isHidden = true
        status.titleLabel?.isHidden = true
        status.backgroundView.backgroundColor = UIColor.red
        status.bodyLabel?.textColor = UIColor.white
        status.configureContent(body: NSLocalizedString("Please, check your internet connection", comment: "internet failure"))
        return status
    }
}
