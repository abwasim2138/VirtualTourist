//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/12/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import UIKit
import MapKit
import CoreData


//TODO: -  PLACEHOLDERS
class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: - PROPERTIES
    @IBOutlet weak var mapView: MKMapView!
    private var annotations = [MKAnnotation]()
    private var pins = [Pin]()
    private var pin: Pin?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let results = fetchedResult()
        for pin in results {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude as! Double, longitude: pin.longitude as! Double)
            annotations.append(annotation)
            pins.append(pin)
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.addAnnotations(self.annotations)
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBarHidden = true
        let ann = mapView.selectedAnnotations
        mapView.deselectAnnotation(ann.first, animated: true)
    }
    

    //MARK: - MAPVIEW
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView!.pinTintColor = UIColor.purpleColor()
            pinView!.animatesDrop = true
            pinView?.draggable = true
            let moveGR = UITapGestureRecognizer(target: self, action: "segueTap:")
            pinView?.addGestureRecognizer(moveGR)
            
        }else{
            pinView?.annotation = annotation
        }
        
        
        return pinView
    }
    
    
    //CITE: http://stackoverflow.com/questions/29776853/ios-swift-mapkit-making-an-annotation-draggable-by-the-user
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
    
        let oldAnnotation = view.annotation!
        switch newState {
        case .Starting:
            updatePin(oldAnnotation)
        case .Ending, .Canceling:
            view.dragState = .None
            annotations.append(view.annotation!)
            addPin(view.annotation!)
        default:
            break
        }
        
    }
    
    func dropPin (sender: UILongPressGestureRecognizer) {
        if sender.state.rawValue == 1 { //TO PREVENT MULTIPLE DROPS IN THE SAME SPOT
        let annotation = MKPointAnnotation()
        let point = sender.locationInView(self.mapView)
        let coord = mapView.convertPoint(point, toCoordinateFromView: mapView)
        annotation.coordinate = coord
        annotation.title = "PIN"
        annotations.append(annotation)
        addPin(annotation)
        dispatch_async(dispatch_get_main_queue()) {
        self.mapView.addAnnotation(annotation)
            }
        }
    
    }
    
    func updatePin (oldAnnotation: MKAnnotation) {
        for pin in pins {
            let coord = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude!), CLLocationDegrees(pin.longitude!))
            if "\(coord)" == "\(oldAnnotation.coordinate)" {
                let index = pins.indexOf(pin)
                pins.removeAtIndex(index!)
                annotations.removeAtIndex(index!)
                sharedContext.deleteObject(pin)
            }
        }
    }
    
    func segueTap (sender: UITapGestureRecognizer) {
        let view = sender.view as! MKAnnotationView
        if let annotation = view.annotation {
            for pin in pins {
                let coord = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude!), CLLocationDegrees(pin.longitude!))
                if "\(coord)" == "\(annotation.coordinate)" {
                    self.pin = pin
                }
            }
        }
        
        performSegueWithIdentifier("showAlbum", sender: self)
    }
    

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if let region = UserSettings.getSettings() {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //SAVE REGION HERE 
        UserSettings.saveSettings(mapView.region)
    }
    
    // MARK: - CORE DATA 
    
    func fetchedResult ()-> [Pin] {
       let fetchRequest = NSFetchRequest(entityName: "Pin")
        var pin = [Pin]()
        do {
        pin = try self.sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        }catch let error as NSError {
            print(error)
        }
        return pin
    }
    
    
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func addPin (annotation: MKAnnotation) {
        let dictionary: [String: AnyObject] = [
            Pin.Keys.Lat : annotation.coordinate.latitude,
            Pin.Keys.Long : annotation.coordinate.longitude,
        ]
        let pin = Pin(dictionary: dictionary, context: sharedContext)
        self.pins.append(pin)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        //PRE FETCH IMAGES FOR PIN HERE
        let coords = CLLocationCoordinate2D(latitude: annotation.coordinate.latitude + 0.1, longitude: annotation.coordinate.longitude)
        let doubleVersionLat = Double(coords.latitude)
        let doubleVersionLong = Double(coords.longitude)
        FlickerAPI.getImagesFromFlickr(doubleVersionLat, long: doubleVersionLong, completionHandler: { (images, error) -> Void in
            if error == nil && images != [] {
                self.sharedContext.performBlock({
                    //CITE: CONCURRENCY FIX BASED OFF OF https://discussions.udacity.com/t/thread-safe-context/37597/2
                    
                    let _ = images.map({ (imageURL: String) -> Photo in
                        let photo = Photo(url: imageURL, context: self.sharedContext)
                        photo.pin = pin
                        
                        return photo
                        
                    })
                   
                    CoreDataStackManager.sharedInstance().saveContext() //TRY HERE
                })
            }
        })
    }
    

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAlbum" {
            let pAVC = segue.destinationViewController as! PhotoAlbumViewController
            pAVC.pin = self.pin
        }
    }

}
