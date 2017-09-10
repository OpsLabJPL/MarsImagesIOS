//
//  TimeViewController.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/13/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import MarsTimeConversion

class TimeViewController: UIViewController {
    
    @IBOutlet weak var earthTimeLabel: UILabel!
    @IBOutlet weak var oppyTimeLabel: UILabel!
    @IBOutlet weak var mslTimeLabel: UILabel!
    
    var dateFormat = DateFormatter()
    let timeZone = TimeZone(abbreviation: "UTC")
    var timeFormat = DateFormatter()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormat.timeZone = timeZone
        dateFormat.dateFormat = "yyyy-DDD"
        timeFormat.timeZone = timeZone
        timeFormat.dateFormat = "HH:mm:ss"
        
        //start clock update timer
        timer = Timer.scheduledTimer(timeInterval: 0.50, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        updateTime()
    }
    
    func updateTime() {
        let today = Date(timeIntervalSinceNow: 0)
        earthTimeLabel.text = "\(dateFormat.string(from: today))T\(timeFormat.string(from: today)) UTC"
        let oppy = Mission.missions[Mission.OPPORTUNITY]!
        var timeDiff = today.timeIntervalSince(oppy.epoch!)
        timeDiff /= MarsTimeConversion.EARTH_SECS_PER_MARS_SEC
        var sol = Int(timeDiff/86400)
        timeDiff -= Double(sol * 86400)
        var hour = Int(timeDiff / 3600)
        timeDiff -= Double(hour * 3600)
        var minute = Int(timeDiff / 60)
        var seconds = Int(timeDiff - Double(minute*60))
        sol += 1  //MER convention of landing day sol 1
        oppyTimeLabel.text = String(format:"Sol %03d %02d:%02d:%02d", sol, hour, minute, seconds)

        let curiosityTime = Date(timeIntervalSinceNow: 0)
        let marsTime = MarsTimeConversion.getMarsTime(curiosityTime, longitude: MarsTimeConversion.CURIOSITY_WEST_LONGITUDE)
        let msd = marsTime.msd
        let mtc = marsTime.mtc
        sol = Int(msd-(360.0-MarsTimeConversion.CURIOSITY_WEST_LONGITUDE)/360.0)-49268
        let mtcInHours:Double = canonicalValue24(mtc - MarsTimeConversion.CURIOSITY_WEST_LONGITUDE*24.0/360.0)
        hour = Int(mtcInHours)
        minute = Int((mtcInHours-Double(hour))*60.0)
        seconds = Int((mtcInHours-Double(hour))*3600 - Double(minute*60))
        //    curiositySolLabel.text = [NSString stringWithFormat:@"Sol %03d", sol];
        //    curiosityTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", hour, minute];
        //    curiositySeconds.text = [NSString stringWithFormat:@":%02d", seconds];
//        _curiosityTimeLabel.text = [NSString stringWithFormat:@"Sol %03d %02d:%02d:%02d", sol, hour, minute, seconds];
        mslTimeLabel.text = String(format:"Sol %03d %02d:%02d:%02d", sol, hour, minute, seconds)
        self.view.setNeedsDisplay()
    }
    
    func canonicalValue24(_ hours:Double) -> Double {
        if hours < 0 {
            return 24 + hours
        }
        else if hours > 24 {
            return hours - 24
        }
        return hours
    }
}
