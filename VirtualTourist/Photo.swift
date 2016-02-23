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
    
    init(url: NSURL ,context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        imagePath = "\(url)"
    }
    
    var photo: UIImage? {
        get {
        if let data = NSData(contentsOfURL: NSURL(string: self.imagePath!)!) {
           let image = UIImage(data: data)
            return image
            }
        return UIImage()
        }
    }

}
