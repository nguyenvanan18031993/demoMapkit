//
//  ViewController.swift
//  MapkitDemo
//
//  Created by AnNguyen on 05/07/2021.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    var mapView = MKMapView()
    var locationManager = CLLocationManager()
    var pin = UIImageView()
    var adddressLabel = UILabel()
    var button = UIButton()
    var previousLocation: CLLocation?
    var directionArray: [MKDirections] = []
    
    let regionInMeters: Double = 10000
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        pin.image = UIImage(named: "pin")
        
        adddressLabel.backgroundColor = .white
        adddressLabel.textAlignment = .center
        adddressLabel.text = ""
        adddressLabel.textColor = .black
        
        button.setTitle("Get Dirrection", for: .normal)
        button.backgroundColor = .red
        button.titleLabel?.textColor = .white
        button.addTarget(self, action: #selector(actionButton), for: .touchUpInside)

        self.view.addSubview(mapView)
        self.view.addSubview(pin)
        self.view.addSubview(adddressLabel)
        self.view.addSubview(button)
        
        adddressLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        adddressLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        adddressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        adddressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        pin.translatesAutoresizingMaskIntoConstraints = false
        adddressLabel.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pin.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pin.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: adddressLabel.topAnchor),
            button.heightAnchor.constraint(equalToConstant: 40),
            button.widthAnchor.constraint(equalToConstant: 120)
            
        ])
        
        checkLocationsServices()
    }
    
    func getDirrection() {
        guard let location = locationManager.location?.coordinate else {
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let direction = MKDirections(request: request)
        resetMapView(withNew: direction)
        direction.calculate { [weak self] (response, error) in
            guard let response = response else { return }
            
            for route in response.routes {
                self?.mapView.addOverlay(route.polyline)
                self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
    }
    
    @objc func actionButton(sender: UIButton) {
        getDirrection()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region  = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationsServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checlLocationAuthorization()
        } else {
            print("Error")
        }
    }
    
    func checlLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            previousLocation = getCenterLocation(for: mapView)
        @unknown default:
            print("error ")
        }
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let lat = mapView.centerCoordinate.latitude
        let long = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: lat, longitude: long)
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionArray.append(directions)
        let _ = directionArray.map { $0.cancel() }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (pleacemark, error) in
            guard let self = self else { return }
            
            if let _ = error {
                return
            }
            
            guard let pleacemark = pleacemark?.first else {
                return
            }
            
            let streetNumber = pleacemark.subThoroughfare ?? ""
            let streetName = pleacemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.adddressLabel.text = streetNumber + streetName
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .red
        
        return renderer
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checlLocationAuthorization()
    }
}
