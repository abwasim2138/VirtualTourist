//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Abdul-Wasai Wasim on 2/12/16.
//  Copyright © 2016 Laylapp. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource,UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    //MARK: - PROPERTIES
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    
    var annotation = MKPointAnnotation()
    var pin: Pin!
    let geoCoder = CLGeocoder()
    var images = [UIImage]()
    var noImagesLabel = UILabel()
    var indexP: [NSIndexPath]!
    var needNew = false
    var placeHolderCount = 0
    
    //CITE: COLOR COLLECTION
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    //MARK: - UI RELATED
    override func viewDidLoad() {
        super.viewDidLoad()
        
       setUpUI()
       fetchPhotos()
    }
  
    func fetchPhotos() {
        do {
            try fetchedResultsController.performFetch()
        }catch let error as NSError{
            print(error)
        }
        self.fetchedResultsController.delegate = self
     
    }
    
    
    func setUpUI () {
        navigationController?.navigationBarHidden = false
        
        //NO IMAGES LABEL 
        noImagesLabel.text = "Loading Photos...."  //HOW TO DISPLAY THIS
        noImagesLabel.textAlignment = .Center
        noImagesLabel.frame = view.frame
        view.addSubview(noImagesLabel)
        
        //CITE UIFundamentals II
        let size = (view.frame.size.width - (6.0)) / 3
        flowLayout.minimumInteritemSpacing = 3.0
        flowLayout.minimumLineSpacing = 3.0
        flowLayout.itemSize = CGSizeMake(size, size)
        
        if pin == self.pin {
            annotation.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(self.pin.latitude!), CLLocationDegrees(self.pin.longitude!))
            mapView.setRegion(MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(0.5), longitudeDelta: CLLocationDegrees(0.5))), animated: true)
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(self.annotation)
            })

        }
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        if pin.photos.isEmpty {
            noImagesLabel.text = "Sorry No Images Available For This Location"
        }
    }
    
    
    func getPhotos () {
        if pin.photos.isEmpty || needNew {
            needNew = false
            let coords = CLLocationCoordinate2D(latitude: annotation.coordinate.latitude + 0.1, longitude: annotation.coordinate.longitude)
            let doubleVersionLat = Double(coords.latitude)
            let doubleVersionLong = Double(coords.longitude)
        
            FlickerAPI.getImagesFromFlickr(doubleVersionLat, long: doubleVersionLong, completionHandler: { (images, error) -> Void in
                if error == nil && images != [] {
            
                self.sharedContext.performBlock({
                //CITE: CONCURRENCY FIX BASED OFF OF https://discussions.udacity.com/t/thread-safe-context/37597/2

                let _ = images.map({ (imageURL: String) -> Photo in
                    let photo = Photo(url: imageURL, context: self.sharedContext)
                    photo.pin = self.pin
                    return photo

                })
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.placeHolderCount = images.count
                        self.noImagesLabel.hidden = true
                        self.newCollection.enabled = true
                    })
                    CoreDataStackManager.sharedInstance().saveContext() //TRY HERE
                        })
            
        
                }else{
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.noImagesLabel.text = "Sorry No Images Available For This Location"
                        self.noImagesLabel.hidden = false
                    })

                }
            })
        }else{
            noImagesLabel.hidden = true
            self.collectionView.reloadData()
        }
        
    }
    
    //MARK: - CORE DATA 
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
       let fetchRequest = NSFetchRequest(entityName: "Photo")
       fetchRequest.sortDescriptors = []
       fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
       
       let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()
    
    //MARK: - NSFETCHEDCONTROLLERDELEGATE 
    //CITE: ColorCollection
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
                insertedIndexPaths.append(newIndexPath!)
        case .Delete:
                deletedIndexPaths.append(indexPath!)
        case .Update:
                updatedIndexPaths.append(indexPath!)
        case .Move: break
        }
        
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
               self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
                
            }
            
            }, completion: nil)
    }
    
    
    //MARK: - UICOLLECTIONVIEWDATASOURCE
    

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("pinCell", forIndexPath: indexPath) as! CollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo
      
        self.configureCell(cell, photo: photo)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        newCollection.title = "REMOVE PHOTO"
        if indexP == nil {indexP = [NSIndexPath]()}
        indexP.append(indexPath)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        cell.imageView.alpha = 0.5

    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        noImagesLabel.hidden = true
        newCollection.enabled = true
        
       
    }
    
    //MARK: - ConfigureCell
    
    func configureCell(cell: CollectionViewCell, photo: Photo?) {
        
        dispatch_async(dispatch_get_main_queue()) { //AS SUGGESTED IN CODE REVIEW
            cell.imageView.image = UIImage(named: "placeHolder")
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
        }
        
        //CITE: GLOBAL QUEUE http://pawanpoudel.svbtle.com/fixing-core-data-concurrency-violations
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            
            var iP: String?
            var imageHolder: UIImage?
            self.sharedContext.performBlockAndWait({
               imageHolder = photo?.photo
            })
            if let photo = imageHolder {
                dispatch_async(dispatch_get_main_queue(), {
                cell.imageView.image = photo
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.hidden = true
            })
            }else {
               self.sharedContext.performBlockAndWait({
                iP = photo!.imagePath
              })
            }
            guard let string = iP else {
                return
            }
            
            guard let data = NSData(contentsOfURL: NSURL(string: string)!) else {
                return
            }
                let image = UIImage(data: data)
                photo!.photo = image
                dispatch_async(dispatch_get_main_queue(), {
                    cell.imageView.image = image
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.hidden = true

                })
        }

            cell.imageView.alpha = 1.0
        
    }
    
    
    //MARK: - UIACTION
    
    @IBAction func getNewCollection(sender: UIBarButtonItem) {
        if newCollection.title == "New Collection" {
        needNew = true
        indexP = (collectionView.indexPathsForVisibleItems())
        newCollection.enabled = false
        noImagesLabel.text = "Loading Photos...."
        noImagesLabel.hidden = false
        deletePhotos()
        getPhotos()
        }else{
          newCollection.title = "New Collection"
          deletePhotos()
        }
    }
    
    func deletePhotos() {
        for iP in indexP {
            let photo = fetchedResultsController.objectAtIndexPath(iP) as! Photo
            sharedContext.deleteObject(photo)
        }
        indexP = nil
        CoreDataStackManager.sharedInstance().saveContext()
    }

}


