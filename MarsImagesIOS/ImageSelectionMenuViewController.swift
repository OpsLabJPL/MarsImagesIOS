//
//  ImageSelectionMenuViewController.swift
//  MarsImages
//
//  Created by Powell, Mark W (397F) on 11/23/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit

class ImageSelectionMenuViewController : UITableViewController {
    
    var imageNames:[String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var imageVC:MarsImageViewController!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "imageNameCell")!
        cell.textLabel?.text = imageNames[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let name = imageNames[row]
        if name == "Anaglyph" {
            imageVC.showAnaglyph()
        } else {
            imageVC.setImageAt(row, name)
        }
        dismiss(animated: true, completion: nil)
    }
}


