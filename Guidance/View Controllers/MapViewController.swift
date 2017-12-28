//
//  MapView.swift
//  Guidance
//
//  Created by hai nguyen on 11/10/17.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var messageManager: MessageManager!
    var isMapViewCentered = false
    let zoomSpan = MKCoordinateSpanMake(0.0005, 0.0005)

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        mapView.showsUserLocation = true;
        
        print("loaded map view")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.camera.heading = newHeading.magneticHeading
        mapView.setCamera(mapView.camera, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = MKPointAnnotation()
        newLocation.coordinate = locations[0].coordinate
        if (!isMapViewCentered){
            mapView.centerCoordinate = newLocation.coordinate
            let region = MKCoordinateRegion(center: newLocation.coordinate, span: zoomSpan)
            mapView.setRegion(region, animated: false)
            isMapViewCentered = true
        }
        print(String(newLocation.coordinate.latitude) + " " + String(newLocation.coordinate.longitude))
        messageManager.fetchMessage(range: 50, userCoordinate: newLocation.coordinate, onComplete: {() in
            for message in self.messageManager.messages{
                let anno = MKPointAnnotation()
                anno.coordinate = message.location.coordinate
                if(message.messageContent!.count == 0) {message.messageContent = "something"}
                anno.title = message.messageContent
                
                self.mapView.addAnnotation(anno)
            }
        })
        self.locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("can not access location")
        let alert = UIAlertController(
            title: "Cannot access location",
            message: "check your location settings",
            preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {return nil}
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
            print("aaaaaaaa")
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.animatesWhenAdded = true
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: 0, y:0)
            view.rightCalloutAccessoryView = UIButton(type: .custom)
            view.leftCalloutAccessoryView = UIButton(type: .custom)
            print("bbbbbbbbb")
        }
        return view
    }
}

