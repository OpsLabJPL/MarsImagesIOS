//
//  Mission.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class Mission {
    static let names = [ OPPORTUNITY, SPIRIT, CURIOSITY ]
    static let missionKey = "mission"
    static let OPPORTUNITY = "Opportunity"
    static let SPIRIT = "Spirit"
    static let CURIOSITY = "Curiosity"
    let EARTH_SECS_PER_MARS_SEC = 1.027491252
    static let missions:[String:Mission] = [OPPORTUNITY: Opportunity(), SPIRIT: Spirit(), CURIOSITY: Curiosity()]
    static let slashAndDot = CharacterSet(charactersIn: "/.")
    
    var epoch:Date?
    var formatter:DateFormatter
    var eyeIndex = 0
    var instrumentIndex = 0
    var sampleTypeIndex = 0
    var cameraFOVs = [String:Double]()
    
    static func currentMission() -> Mission {
        return missions[currentMissionName()]!
    }
    
    static func currentMissionName() -> String {
        let userDefaults = UserDefaults.standard
        if userDefaults.value(forKey: missionKey) == nil {
            userDefaults.set(OPPORTUNITY, forKey: missionKey)
            userDefaults.synchronize()
        }
        return userDefaults.value(forKey: missionKey) as! String
    }
    
    static func imageId(url:String) -> String {
        let tokens = url.components(separatedBy: slashAndDot)
        let numTokens = tokens.count
        let imageId = tokens[numTokens-2]
        return imageId.removingPercentEncoding ?? ""
    }
    
    func urlPrefix() -> String {
        return ""
    }
   
    func sol(_ title: String) -> Int {
        let tokens = title.components(separatedBy: " ")
        if tokens.count >= 2 {
            return Int(tokens[1])!
        }
        return 0;
    }
    
    init() {
        self.formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
    }
    
    func rowTitle(_ title: String) -> String {
        return title
    }
    
    func subtitle(_ title: String) -> String {
        let marstime = tokenize(title).marsLocalTime
        return "\(marstime) LST"
    }
    
    func caption(_ title: String) -> String {
        let t = tokenize(title)
        return "\(t.instrumentName) image taken on Sol \(t.sol)."
    }
    
    func tokenize(_ title: String) -> Title {
        return Title()
    }
    
    func getSortableImageFilename(url: String) -> String {
        return url
    }

    func solAndDate(sol:Int) -> String {
        let interval = Double(sol*24*60*60)*EARTH_SECS_PER_MARS_SEC
        let imageDate = Date(timeInterval: interval, since: epoch!)
        let formattedDate = formatter.string(from: imageDate)
        return "Sol \(sol) \(formattedDate)"
    }
 
    func imageName(imageId: String) -> String {
        print("You should never call me: override me in a subclass instead.")
        return ""
    }
    
    func stereoImageIndices(imageIDs: [String]) -> (Int,Int)? {
        print("You should never call me: override me in a subclass instead.")
        return nil
    }
  
    func getInstrument(imageId:String) -> String {
        let irange = imageId.index(imageId.startIndex, offsetBy: instrumentIndex)..<imageId.index(imageId.startIndex, offsetBy: instrumentIndex+1)
        return String(imageId[irange])
    }
    
    func getEye(imageId:String) -> String {
        let erange = imageId.index(imageId.startIndex, offsetBy: eyeIndex)..<imageId.index(imageId.startIndex, offsetBy:eyeIndex+1)
        return String(imageId[erange])
    }
    
    func getCameraId(imageId: String) -> String {
        print("You should never call me: override me in a subclass instead.")
        return ""    
    }
    
    func getCameraFOV(cameraId:String) -> Double {
        let fov = cameraFOVs[cameraId]
        guard fov != nil else {
            print("Brown alert: requested camera FOV for unrecognized camera id: \(cameraId)")
            return 0.0
        }
        return fov!
    }
    
    func layer(cameraId:String) -> Int {
        if cameraId.hasPrefix("N") {
            return 2;
        } else {
            return 1;
        }
    }
    
    func mastPosition() -> [Double] {
        print("You should never call me: override me in a subclass instead.")
        return [0,0,0]
    }

}

class Title {
    var sol = 0
    var imageSetID = ""
    var instrumentName = ""
    var marsLocalTime = ""
    var siteIndex = 0
    var driveIndex = 0
}

// http://www.dracotorre.com/blog/swift-substrings/
// extend String to enable sub-script with Int to get Character or sub-string
extension String
{
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    // for convenience we should include String return
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(self.startIndex, offsetBy: r.upperBound)
        
        return String(self[start...end])
    }
}
