//
//  FlickerAPI.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/12/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit


//CITE: FlickFinder


let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "dab97801a4c250eb4c5fc9e42c6f9fb0"
//SECRET = 84e9eecfd0ed28bb
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let BOUNDING_BOX_HALF_WIDTH = 0.4
let BOUNDING_BOX_HALF_HEIGHT = 0.4
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

class FlickerAPI {
    private static let session = NSURLSession.sharedSession()
    
    //REFACTORED CODE FOUND IN FLICK FINDER
    static func requestData (methodArguments: [String: AnyObject], completionHandler: (imagesDictionary: NSDictionary?, error: NSError?)->Void)->NSURLSessionTask {
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            guard error == nil else {
                return completionHandler(imagesDictionary: nil, error: error)
            }
            
            guard let statusCodeCheck = (response as? NSHTTPURLResponse)?.statusCode where statusCodeCheck >= 200 && statusCodeCheck <= 299 else {
                 return completionHandler(imagesDictionary: nil, error: nil)
            }
            
            guard let data = data else {
                return completionHandler(imagesDictionary: nil, error: nil)
            }
            
            parseJSONData(data, completionHandler: { (parsedResult, error) -> Void in
                
                guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                    
                    return completionHandler(imagesDictionary: nil, error: nil)
                }
                
                guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                    
                    return completionHandler(imagesDictionary: nil, error: nil)
                }
                
                completionHandler(imagesDictionary: photosDictionary, error: nil)
                
                 })
            }
        task.resume()
        return task
    }
    
    static func getImagesFromFlickr(lat: Double, long: Double, completionHandler: (images: [NSURL], error: NSError?)->Void)->NSURLSessionTask {
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(lat,long: long),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        let task = requestData(methodArguments) { (imagesDictionary, error) -> Void in
            guard error == nil else {
                return print(error?.localizedDescription)
            }
            
            guard let totalPages = imagesDictionary!["pages"] as? Int else {
                return completionHandler(images: [], error: nil)
            }
            
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage, completionHandler: { (images, error) -> Void in
                completionHandler(images: images, error: error)
            })
        }
        
        task.resume()
        
        return task
    }

    static func parseJSONData(data: NSData, completionHandler: (result: AnyObject!, error: NSError?)-> Void){
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }catch{
            let userInfo = [NSLocalizedDescriptionKey: "\(data)"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONData", code: 1, userInfo: userInfo))
        }
        completionHandler(result: parsedResult, error: nil)
    }
   
    static func createBoundingBoxString(lat: Double, long: Double) -> String {
        
        let latitude = lat
        let longitude = long
        
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    static func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"

            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    static func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (images: [NSURL], error: NSError?)->Void) {
           print("GET TO PAGE PART")
        
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let task = requestData(withPageDictionary) { (photosDictionary, error) -> Void in

            guard let totalPhotosVal = (photosDictionary!["total"] as? NSString)?.integerValue else {
                return completionHandler(images: [], error: nil)
            }
            
            if totalPhotosVal > 0 {
                guard let photosArray = photosDictionary!["photo"] as? [[String: AnyObject]] else {
                    return completionHandler(images: [], error: nil)
                }
                var images = [NSURL]()
                var condition = 12
                if photosArray.count < 12 {
                    condition = photosArray.count
                }
                for var i = 0; i < condition;i++ {
                    let randomPhotoIndex = Int(arc4random() % UInt32(photosArray.count))
                    let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                    
                    guard let imageUrlString = photoDictionary["url_m"] as? String else {
                        return completionHandler(images: [], error: nil)
                    }
                    
                    if let imageURL = NSURL(string: imageUrlString) {
                    images.append(imageURL)
                    }else{
                        return completionHandler(images: [], error: nil)
                    }

                }
                completionHandler(images: images, error: nil)
            } else {
                print("NOTHING FOUND")
                let url = [NSURL]()
                print(url)
                completionHandler(images: url, error: nil)
            }
        }
        
        task.resume()
    }
    
}