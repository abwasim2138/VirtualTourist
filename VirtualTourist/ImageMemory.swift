//
//  ImageMemory.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/27/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import UIKit

//CITE: BASED OFF OF IMAGECACHE FILE IN FAVORITE ACTORS APP
class ImageMemory {
    
    class func retrieveImage(pathComponent: String)->UIImage? {
        let path = makePath(pathComponent)
        
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)!
        }
        
        return nil
    }
    
    
    class func saveImage (image: UIImage? ,pathComponent: String) {

        let path = makePath(pathComponent)
        let data = UIImagePNGRepresentation(image!)
        print("RANGER : \(pathComponent)")

        //SAVE TO DOCUMENTS DIRECTORY
        do {
        try data!.writeToFile(path, options: NSDataWritingOptions.AtomicWrite)
            print("SAVED")
        }catch let error as NSError {
            print("ERROR IN SAVING \(error.localizedFailureReason)")
        }
    }
    
    class func deleteImage (pathComponent: String) {
        
        let path = makePath(pathComponent)
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
            print("ITEM REMOVED")
        }catch let error as NSError {
            print("ERROR IN DELETING IMAGEPATH \(error.userInfo)")
        }
        } else {
            print("FILE DOESN'T EXIST")
        }
    }
    
    class func makePath(pathComponent: String)-> String {
        
        let range = Range(start: pathComponent.startIndex, end: pathComponent.startIndex.advancedBy(35))
        let ranger = pathComponent.stringByReplacingCharactersInRange(range, withString: "")
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let path = documentsDirectoryURL.URLByAppendingPathComponent(ranger)
        return path.path!
        
    }
    
}