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

class MapView: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var label_latlon: UILabel!
    var locationManager: CLLocationManager!
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
//        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        self.view.bringSubview(toFront: label_latlon)

    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = MKPointAnnotation()
        newLocation.coordinate = locations[0].coordinate

        mapView.addAnnotation(newLocation)
        mapView.centerCoordinate = newLocation.coordinate
        label_latlon.text =  String(newLocation.coordinate.latitude) + " " + String(newLocation.coordinate.longitude)
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        label_latlon.text = "cannot update current location"
    }

}
