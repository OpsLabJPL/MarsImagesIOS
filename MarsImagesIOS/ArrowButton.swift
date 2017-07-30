//
//  ArrowButton.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/29/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit

@IBDesignable

/// UIButton subclass which draws an error of the specified size in the middle of the view
open class ArrowButton: UIButton {
    
    // MARK: Variables
    /// The direction of the arrow. If true, arrow points left. If false, right.
    @IBInspectable public var leftDirection:Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// The color of the arrow
    @IBInspectable public var arrowColor:UIColor = UIColor.darkGray {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// The width of the arrow
    @IBInspectable public var arrowWidth:CGFloat = 20.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// The height of the arrow
    @IBInspectable public var arrowHeight:CGFloat = 30.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    open override func draw(_ rect: CGRect) {
        if self.leftDirection {
            let path = UIBezierPath()
            let rectX = (bounds.width - self.arrowWidth) / 2
            let rectY = (bounds.height - self.arrowHeight) / 2
            let arrowRect = CGRect(x: rectX, y: rectY, width: self.arrowWidth, height: self.arrowHeight)
            path.move(to: CGPoint(x: arrowRect.origin.x + arrowRect.width, y: arrowRect.origin.y))
            path.addLine(to: CGPoint(x:arrowRect.origin.x, y: arrowRect.origin.y + arrowRect.height / 2))
            path.addLine(to: CGPoint(x:arrowRect.origin.x + arrowRect.width, y:arrowRect.origin.y + arrowRect.height))
            path.addLine(to: CGPoint(x: arrowRect.origin.x + arrowRect.width, y: arrowRect.origin.y))
            self.arrowColor.setFill()
            path.fill()
        } else {
            let path = UIBezierPath()
            let rectX = (bounds.width - self.arrowWidth) / 2
            let rectY = (bounds.height - self.arrowHeight) / 2
            let arrowRect = CGRect(x: rectX, y: rectY, width: self.arrowWidth, height: self.arrowHeight)
            path.move(to: arrowRect.origin)
            path.addLine(to: CGPoint(x:arrowRect.origin.x + arrowRect.width, y: arrowRect.origin.y + arrowRect.height / 2))
            path.addLine(to: CGPoint(x:arrowRect.origin.x, y:arrowRect.origin.y + arrowRect.height))
            path.addLine(to: arrowRect.origin)
            self.arrowColor.setFill()
            path.fill()
        }
    }
}
