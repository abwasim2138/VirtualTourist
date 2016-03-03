//
//  UserSettings.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/18/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import Foundation
import MapKit

private let SAVE_KEY = "save"

class UserSettings {

    private static let userDefaults = NSUserDefaults.standardUserDefaults()
    
    class func saveSettings(region: MKCoordinateRegion) {
        let lat = Double(region.center.latitude)
        let long = Double(region.center.longitude)
        let latD = Double(region.span.latitudeDelta)
        let longD = Double(region.span.longitudeDelta)
        let settings = [lat,long,latD,longD]
        userDefaults.setObject(settings, forKey: SAVE_KEY)
    }
    
    class func getSettings()-> MKCoordinateRegion? {
        if let settings = userDefaults.objectForKey(SAVE_KEY) as? [Double] {
            let center = CLLocationCoordinate2DMake(settings[0], settings[1])
            let span = MKCoordinateSpan(latitudeDelta: settings[2], longitudeDelta: settings[3])
            let region = MKCoordinateRegion(center: center, span: span)
            return region
        }else{
            return nil
        }
    }
}