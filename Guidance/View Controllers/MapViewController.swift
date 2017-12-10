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
    var isMapViewCentered = false
    let zoomSpan = MKCoordinateSpanMake(0.01, 0.01)

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        print("loaded map view")
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

