//
//  EvernoteMarsimageCatalog.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import Alamofire
import CSV
import EvernoteSDK
import ReachabilitySwift
import SwiftyJSON

class EvernoteMarsImageCatalog : MarsImageCatalog {
   
    var mission:String {
        didSet {
            notestore = nil //force reconnect for new notebook
            locations = nil
            namedLocations = nil
            llQuaternions = nil
            searchWords = ""
            DispatchQueue.global().async {
                _ = self.getLocations()
                _ = self.getNamedLocations()
            }
        }
    }
    
    var searchWords = "" {
        didSet {
            isSearchComplete = false
            reload()
        }
    }
    
    var isSearchComplete = false
    var notestore: EDAMNoteStoreClient?
    var userinfo: EDAMPublicUserInfo?
    var user:String?
    
    var sols:[Int] = []
    var solIndices: [Int : Int] = [:]
    var imagesets:[Imageset] = []
    var imagesetCount:Int {
        get {
            return imagesets.count
        }
    }
    var imagesetCountsBySol:[Int:Int] = [:]
    var imagesetsForSol: [Int : [Imageset]] = [:]

    var marsphotos:[MarsPhoto] = []
    var captions:[String?] = []
    
    var locations:[(Int,Int)]?
    var namedLocations:[String:(Int,Int)]?
    var llQuaternions: [Int:[Int:Quaternion]]?
    
    var reachability: Reachability
    
    static let OPPY_NOTEBOOK_ID   = "a7271bf8-0b06-495a-bb48-7c0c7af29f70"
    static let MSL_NOTEBOOK_ID    = "0296f732-694d-4ccd-9f5b-5983dc98b9e0"
    static let SPIRIT_NOTEBOOK_ID = "f1a72415-56e7-4244-8e12-def9be9c512b"
    static let notebookIDs = [Mission.names[0]:OPPY_NOTEBOOK_ID, Mission.names[1]:SPIRIT_NOTEBOOK_ID, Mission.names[2]: MSL_NOTEBOOK_ID ]

    static let OPPY_USER = "opportunitymars"
    static let SPIRIT_USER = "spiritmars"
    static let MSL_USER = "mslmars"
    static let users = [Mission.names[0]: OPPY_USER, Mission.names[1]: SPIRIT_USER, Mission.names[2]: MSL_USER]
    
    static let noteDownloadQueue = DispatchQueue(label: "note downloader")
    
    let notePageSize = 15
    
    let slashAndDot = CharacterSet(charactersIn: "/.")
    
    init(missionName:String) {
        self.mission = missionName
        self.user = EvernoteMarsImageCatalog.users[missionName]
        self.reachability = Reachability(hostname:"evernote.com")!
        do {
            try reachability.startNotifier()
        } catch {
            return
        }
    }
    
    func hasMoreImages() -> Bool {
        return !isSearchComplete
    }
    
    func reload() {
        imagesetsForSol.removeAll()
        imagesets.removeAll()
        marsphotos.removeAll()
        captions.removeAll()
        imagesetCountsBySol.removeAll()
        sols.removeAll()
        solIndices.removeAll()
        loadMoreNotes(startIndex: 0, total: notePageSize)
    }
    
    func reloadLocations() {
        locations = nil
        namedLocations = nil
        _ = getLocations()
        _ = getNamedLocations()
    }
    
    func loadNextPage() {
        loadMoreNotes(startIndex: imagesets.count, total: notePageSize)
    }
    
    func connect() {
        if notestore == nil {
            let userstoreUri = URL(string: "https://www.evernote.com/edam/user")
            let userstoreHttpClient = ENTHTTPClient(url: userstoreUri)
            let userstoreProtocol = ENTBinaryProtocol(transport: userstoreHttpClient)
            let userstore = EDAMUserStoreClient(with: userstoreProtocol)
            
            userinfo = userstore?.getPublicUserInfo(user)
            
            let notestoreUri = URL(string:(userinfo?.noteStoreUrl)!)
            let agentString = "Mars Images/3.0;iOS/\(UIDevice.current.systemVersion)"
            let notestoreHttpClient = ENTHTTPClient(url: notestoreUri, userAgent: agentString, timeout: 15)
                //noteStoreUri userAgent:agentString timeout:15]
            
            let notestoreProtocol = ENTBinaryProtocol(transport: notestoreHttpClient)
                //[[TBinaryProtocol alloc] initWithTransport:noteStoreHttpClient]
            self.notestore = EDAMNoteStoreClient(with: notestoreProtocol)
        }
    }
    
    func loadMoreNotes(startIndex:Int, total:Int) {
        
        guard reachability.isReachable else {
            print("DEBUG got zero notes back, notifying")

            NotificationCenter.default.post(name: .endImagesetLoading, object: nil, userInfo:[numImagesetsReturnedKey:0])
//            isSearchComplete = true
            return
        }
        
        if isSearchComplete {
            print("You should not be asking to loadMoreNotes when the search is already complete.")
        }
    
        connect()
        
        EvernoteMarsImageCatalog.noteDownloadQueue.async {
            guard self.imagesets.count <= startIndex else {
                return
            }
        
            NotificationCenter.default.post(name: .beginImagesetLoading, object: nil)

            let filter = EDAMNoteFilter()
            filter.notebookGuid = EvernoteMarsImageCatalog.notebookIDs[self.mission]
            filter.order = NSNumber(value:NoteSortOrder_TITLE.rawValue)
            filter.ascending = NSNumber(value:false)
            if !self.searchWords.isEmpty {
                filter.words = self.formatSearch(self.searchWords)
            }
            do {
                if let notelist = try self.notestore?.findNotes("", filter: filter, offset: Int32(startIndex), maxNotes: Int32(total)) {
                    for (j, aNote) in notelist.notes.enumerated() {
                        let note = self.reorderResources(aNote)
                        let imageset = EvernoteImageset(note: note, userinfo: self.userinfo!)
                        self.imagesets.append(imageset)
                        let sol = self.sol(note.title)
                        let lastSolIndex = self.sols.count-1
                        if lastSolIndex < 0 || self.sols[lastSolIndex] != sol {
                            self.sols.append(sol)
                            self.solIndices[sol] = self.sols.count-1
                        }
                        var imagesetsInSol = self.imagesetsForSol[sol]
                        if imagesetsInSol == nil {
                            imagesetsInSol = []
                        }
                        imagesetsInSol!.append(imageset)
                        self.imagesetsForSol[sol] = imagesetsInSol!
                        let photo = self.getNotePhoto(j+startIndex, imageIndex:0)
                        self.marsphotos.append(photo)
                        self.captions.append(Mission.currentMission().caption(imageset.title))
                        self.imagesetCountsBySol[sol] = imagesetsInSol!.count
                        if self.imagesetCountsBySol.count != self.sols.count {
                            print("Brown alert: sections and sols counts don't match each other.")
                        }
                    }
                    
                    self.isSearchComplete = notelist.totalNotes.intValue - notelist.startIndex.intValue + notelist.notes.count <= 0
                    print("DEBUG got \(notelist.notes.count) notes back, notifying")
                    NotificationCenter.default.post(name: .endImagesetLoading, object: nil, userInfo:[numImagesetsReturnedKey:notelist.notes.count])
                } else {
                    self.isSearchComplete = true
                }
            } catch {
                print ("\(error)")
            }

        }
    }
    
    func getNotePhoto(_ noteIndex:Int, imageIndex: Int) -> MarsPhoto {
        let imageset = imagesets[noteIndex] as! EvernoteImageset
        if imageIndex >= imageset.note.resources.count {
            print("Brown alert: requested image index is out of bounds.")
        }
        
        let resource = imageset.note.resources[imageIndex]
        let resGUID = resource.guid!
        let imageURL = "\(userinfo!.webApiUrlPrefix!)res/\(resGUID)"
        let marsPhoto = MarsPhoto(url:URL(string:imageURL)!, imageset: imageset, indexInImageset: imageIndex, sourceUrl: resource.attributes.sourceURL, modelJsonString: resource.attributes.cameraModel)
        return marsPhoto
    }
    
    func reorderResources(_ note:EDAMNote) -> EDAMNote {
        var sortedResources:[EDAMResource] = []
        var resourceFilenames:[String] = []
        var resourcesByFile:[String:EDAMResource] = [:]
        
        for resource in note.resources {
            let filename = Mission.currentMission().getSortableImageFilename(url: resource.attributes.sourceURL)
            resourceFilenames.append(filename)
            resourcesByFile[filename] = resource
        }
        
        let sortedFilenames = resourceFilenames.sorted()
        for filename in sortedFilenames {
            sortedResources.append(resourcesByFile[filename]!)
        }
        
        note.resources = sortedResources
        return note
    }
    
    func sol(_ noteTitle:String) -> Int {
        let tokens = noteTitle.components(separatedBy: " ")
        if tokens.count >= 2 {
            if let sol = Int(tokens[1]) {
                return sol
            }
        }
        return 0
    }
    
    func formatSearch(_ searchWords:String) -> String {
        let words = searchWords.components(separatedBy: .whitespacesAndNewlines)
        var formattedText = ""
        for w in words {
            var word = w

            let wordIntValue = Int(word)
            if word.count == 13 && word[word.index(word.startIndex, offsetBy:6)] == "-" {
                //do nothing for an RMC formatted as XXXXXX-XXXXXX
            }
            else if let wordIntValue = wordIntValue {
                if wordIntValue > 0 && !word.hasSuffix("*") {
                    let formattedInt = String(format:"%05d", wordIntValue)
                    word = "\"Sol \(formattedInt)\""
                }
            }
            else {
                word.append("*") //match partial word like Nav*, Pan*, Mast*, Haz*
            }
            
            if !formattedText.isEmpty {
                formattedText.append(" ")
            }
            
            formattedText.append("intitle:\(word)")
        }
        print("search filter: \(formattedText)")
        return formattedText
    }
    
    func imageName(imageset: Imageset, imageIndexInSet: Int) -> String {
        if let imageset = imageset as? EvernoteImageset {
            if imageIndexInSet < imageset.note.resources.count {
                let resource = imageset.note.resources[imageIndexInSet]
                let imageId = imageID(url:resource.attributes.sourceURL)
                return Mission.currentMission().imageName(imageId: imageId)
            }
        }
        return ""
    }
    
    func imageID(url: String) -> String {
        let tokens = url.components(separatedBy: slashAndDot)
        let numTokens = tokens.count
        var imageid = tokens[numTokens-2]
        imageid = imageid.removingPercentEncoding!
        return imageid;
    }
    
    func getImagesetCount(imageset: Imageset) -> Int {
        if let imageset = imageset as? EvernoteImageset {
            return imageset.note.resources.count
        }
        return 1
    }
    
    func changeToImage(imagesetIndex: Int, imageIndexInSet: Int) {        
        let photo = getNotePhoto(imagesetIndex, imageIndex: imageIndexInSet)
        marsphotos[imagesetIndex] = photo
    }
    
    func changeToAnaglyph(leftAndRight: (Int,Int), imageIndex: Int) {
        let imageset = imagesets[imageIndex] as! EvernoteImageset
        let leftResource = imageset.note.resources[leftAndRight.0]
        let rightResource = imageset.note.resources[leftAndRight.1]
        let urls = (leftResource.attributes.sourceURL as String,
                    rightResource.attributes.sourceURL as String)
        
        let anaglyph = MarsPhoto(imagesets[imageIndex], leftAndRight:urls)
        marsphotos[imageIndex] = anaglyph
    }
    
    func stereoForImages(imagesetIndex: Int) -> (Int, Int)? {
        let imageset = imagesets[imagesetIndex] as! EvernoteImageset
        guard imageset.note.resources.count > 0 else {
            return nil
        }
        
        var imageIDs:[String] = []
        for r in imageset.note.resources {
            imageIDs.append(imageID(url:r.attributes.sourceURL))
        }

        if let stereoImageIndices = Mission.currentMission().stereoImageIndices(imageIDs: imageIDs) {
            let leftImageIndex = stereoImageIndices.0
            let rightImageIndex = stereoImageIndices.1
            let leftResource = imageset.note.resources[leftImageIndex]
            let rightResource = imageset.note.resources[rightImageIndex]

            //check width and height of left and right images and don't return them unless they match
            let leftModel = CameraModelUtils.model(getModelJSON(leftResource))
            let rightModel = CameraModelUtils.model(getModelJSON(rightResource))
            let leftWidth = leftModel.xdim
            let rightWidth = rightModel.xdim
            let leftHeight = leftModel.ydim
            let rightHeight = rightModel.ydim
            if leftWidth == rightWidth && leftHeight == rightHeight {
                return stereoImageIndices
            }
        }
        return nil
    }
    
    func getModelJSON(_ resource: EDAMResource) -> JSON {
        let cmod_string = resource.attributes.cameraModel!
        let jsondata = cmod_string.data(using: .utf8)!
        return JSON(data:jsondata)
    }
    
    func getNearestRMC() -> (Int,Int)? {
        var userSite = 0
        var userDrive = 0
        
        for imageset in imagesets {
            if imageset.title.range(of: "RMC", options: .backwards) != nil {
                let rmcstring = String(imageset.title.suffix(13))
                let indices = rmcstring.components(separatedBy: "-")
                userSite = Int(indices[0])!
                userDrive = Int(indices[1])!
                break
            }
        }

        if let locations = self.locations {
            var location = locations.last!
            if userSite != 0 || userDrive != 0 {
                for rmc in locations.reversed() {
                    if rmc.0*100000+rmc.1 < userSite*100000+userDrive {
                        break
                    }
                    location = rmc
                }
                return location
            }
        }
        return nil
    }
    
    func getNextRMC(rmc:(Int,Int)) -> (Int,Int)? {
        if locations == nil {
            _ = getLocations()
        }
        if let locations = self.locations {
            for i in 0..<locations.count {
                let location = locations[i]
                if location.0 == rmc.0 && location.1 == rmc.1 && i<locations.count-1 {
                    return locations[i+1]
                }
            }
        }
        return nil
    }
    
    func getPreviousRMC(rmc:(Int,Int)) -> (Int,Int)? {
        if locations == nil {
            _ = getLocations()
        }
        if let locations = self.locations {
            for i in 0..<locations.count {
                let location = locations[i]
                if location.0 == rmc.0 && location.1 == rmc.1 && i>0 {
                    return locations[i-1]
                }
            }
        }
        return nil
    }

    func getLocations() -> [(Int,Int)]? {
    
        if locations != nil {
            return locations
        }
    
        let urlPrefix = Mission.currentMission().urlPrefix()
        let locationsURL = URL(string: "\(urlPrefix)/locations/location_manifest.csv")!
        Alamofire.request(locationsURL).responseString{ response in
            if let csvString = response.result.value {
                let csv = try! CSVReader(string: csvString)
                self.locations = []
                while let row = csv.next() {
                    let site = Int(row[0].trimmingCharacters(in: .whitespacesAndNewlines))!
                    let drive = Int(row[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                    self.locations?.append((site,drive))
                }
                NotificationCenter.default.post(name: .locationsLoaded, object: nil, userInfo:nil)
            }
        }
        return locations
    }
    
    func getNamedLocations() -> [String:(Int,Int)]? {
        
        if namedLocations != nil {
            return namedLocations
        }
        
        let urlPrefix = Mission.currentMission().urlPrefix()
        let locationsURL = URL(string: "\(urlPrefix)/locations/named_locations.csv")!
        Alamofire.request(locationsURL).responseString{ response in
            if let csvString = response.result.value {
                let csv = try! CSVReader(string: csvString)
                self.namedLocations = [:]
                while let row = csv.next() {
                    let site = Int(row[0].trimmingCharacters(in: .whitespacesAndNewlines))!
                    let drive = Int(row[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                    let locationName = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    self.namedLocations![locationName] = (site,drive)
                }
                NotificationCenter.default.post(name: .namedLocationsLoaded, object: nil, userInfo:nil)

            }
        }
        return namedLocations
    }
    
    func localLevelQuaternion(_ rmc: (Int, Int), completionHandler: @escaping (Quaternion) -> (Void)) {
        let site = rmc.0, drive = rmc.1
        
        if llQuaternions == nil {
            llQuaternions = Dictionary()
        }
        if llQuaternions![site] == nil {
            llQuaternions![site] = Dictionary()
        }
        
        if let qLL = llQuaternions![site]![drive] {
            //already cached, our work here is done:
            completionHandler(qLL)
        } else {
            //gotta go fetch it from the network
            let urlPrefix = Mission.currentMission().urlPrefix()
            let site6 = String(format:"%06d", site)
            let siteCSVURL = URL(string: "\(urlPrefix)/locations/site_\(site6).csv")!
            Alamofire.request(siteCSVURL).responseString{ response in
                if let csvString = response.result.value {
                    let csv = try! CSVReader(string: csvString)
                    while let row = csv.next() {
                        let driveIndex = Int(row[0].trimmingCharacters(in: .whitespacesAndNewlines))!
                        let q = Quaternion()
                        q.w = Double(row[1].trimmingCharacters(in: .whitespacesAndNewlines))!
                        q.x = Double(row[2].trimmingCharacters(in: .whitespacesAndNewlines))!
                        q.y = Double(row[3].trimmingCharacters(in: .whitespacesAndNewlines))!
                        q.z = Double(row[4].trimmingCharacters(in: .whitespacesAndNewlines))!
                        self.llQuaternions![site]![driveIndex] = q
                    }
                    completionHandler(self.llQuaternions![site]![drive]!)
                }
            }
        }
    }
}

class EvernoteImageset : Imageset {
    
    var note:EDAMNote
    
    init(note:EDAMNote, userinfo:EDAMPublicUserInfo) {
        self.note = note

        super.init(title: note.title)
        
        if note.resources.count > 0 {
            let resource = note.resources[0]
            let resGUID = resource.guid
            self.thumbnailUrl = "\(userinfo.webApiUrlPrefix!)thm/res/\(resGUID!)?size=50"
        }
    }
    
}

