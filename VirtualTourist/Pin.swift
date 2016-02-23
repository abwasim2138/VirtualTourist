//
//  Pin.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/15/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import Foundation
import CoreData


//CITE: TheMovieDB
class Pin: NSManagedObject {

    struct Keys {
        static let Lat = "latitude"
        static let Long = "longitude"
    }
    
    
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
     init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Lat] as? Double
        longitude = dictionary[Keys.Long] as? Double
    }


}
