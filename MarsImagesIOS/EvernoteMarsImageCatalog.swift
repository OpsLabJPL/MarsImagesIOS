//
//  EvernoteMarsimageCatalog.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import EvernoteSDK
import ReachabilitySwift

class EvernoteMarsImageCatalog : MarsImageCatalog {
   
    var mission:String {
        didSet {
            notestore = nil //force reconnect for new notebook
        }
    }
    
    var searchWords = "" {
        didSet {
            reload()
        }
    }
    
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
    
    func reload() {
        imagesetsForSol.removeAll()
        imagesets.removeAll()
        marsphotos.removeAll()
        imagesetCountsBySol.removeAll()
        sols.removeAll()
        solIndices.removeAll()
        loadMoreNotes(startIndex: 0, total: notePageSize)
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
            NotificationCenter.default.post(name: .endImagesetLoading, object: nil, userInfo:[numImagesetsReturnedKey:0])
            return
        }
    
        connect()
        
        EvernoteMarsImageCatalog.noteDownloadQueue.sync {
            guard self.imagesets.count <= startIndex else { return }
        
            NotificationCenter.default.post(name: .beginImagesetLoading, object: nil)

            let filter = EDAMNoteFilter()
            filter.notebookGuid = EvernoteMarsImageCatalog.notebookIDs[self.mission]
            filter.order = NSNumber(value:NoteSortOrder_TITLE.rawValue)
            filter.ascending = NSNumber(value:false)
            if !self.searchWords.isEmpty {
                filter.words = self.formatSearch(self.searchWords)
            }
            if let notelist = self.notestore?.findNotes("", filter: filter, offset: Int32(startIndex), maxNotes: Int32(total)) {
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
                    self.imagesetCountsBySol[sol] = imagesetsInSol!.count
                    if self.imagesetCountsBySol.count != self.sols.count {
                        print("Brown alert: sections and sols counts don't match each other.")
                    }
                }
                NotificationCenter.default.post(name: .endImagesetLoading, object: nil, userInfo:[numImagesetsReturnedKey:notelist.notes.count])
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
        return MarsPhoto(url:URL(string:imageURL)!, imageset: imageset) //TODO FIX MY TECH DEBT extricate MarsPhoto from EDAMNote & EDAMResource
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
            if word.characters.count == 13 && word[word.index(word.startIndex, offsetBy:6)] == "-" {
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

