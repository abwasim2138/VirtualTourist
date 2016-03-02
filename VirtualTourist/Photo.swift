//
//  Photo.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/15/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import Foundation
import CoreData
import UIKit


//CITE: TheMovieDB 
class Photo: NSManagedObject {

    struct Keys {
        static let iPath = "url_m"
    }
    
    @NSManaged var imagePath: String?
    @NSManaged var pin: NSManagedObject?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(url: String ,context: NSManagedObjectContext) {
       
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imagePath = "\(url)"
        
    }
    
    var photo: UIImage? { //NEEDED STILL
        get {
        return ImageMemory.retrieveImage(self.imagePath!)
        }
        set {
        ImageMemory.saveImage(newValue, pathComponent: self.imagePath!)

        }
    }
    
    //AS SUGGESTED IN CODE REVIEW
    override func prepareForDeletion() {
        ImageMemory.deleteImage(self.imagePath!)
    }

}
