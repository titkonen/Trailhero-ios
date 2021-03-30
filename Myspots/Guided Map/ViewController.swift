import UIKit
import MapKit

class ViewController: UIViewController {

    var spots: [Spots] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    let regionRadius: CLLocationDistance = 1000
       func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(
          center: location.coordinate,
          latitudinalMeters: regionRadius,
          longitudinalMeters: regionRadius
        )
         mapView.setRegion(coordinateRegion, animated: true)
         mapView.delegate = self
        
       }
    // MARK: - View Management
    override func viewDidLoad() {
        super.viewDidLoad()

        // set initial location in Kivikko under big rock rolley
        let initialLocation = CLLocation(latitude: 60.2393, longitude: 25.0577)
   
        centerMapOnLocation(location: initialLocation)
        
        mapView.register(SpotsMarkerView.self,
        forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        loadInitialData()
        mapView.addAnnotations(spots)
        
    }
    
    // MARK: - Ask users authorization
    let locationManager = CLLocationManager()
    func checkLocationAuthorizationStatus() {
      if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
        mapView.showsUserLocation = true
      } else {
        locationManager.requestWhenInUseAuthorization()
      }
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      checkLocationAuthorizationStatus()
    }
    
    // MARK: - Functions
    // Loads JSON Data
    func loadInitialData() {
      guard let fileName = Bundle.main.path(forResource: "testdata", ofType: "json")
        else { return }
      let optionalData = try? Data(contentsOf: URL(fileURLWithPath: fileName))

      guard
        let data = optionalData,
        // 2: You use JSONSerialization to obtain a JSON object.
        let json = try? JSONSerialization.jsonObject(with: data),
        // 3: You check that the JSON object is a dictionary with String keys and Any values.
        let dictionary = json as? [String: Any],
        // 4: You’re only interested in the JSON object whose key is "data".
        let works = dictionary["data"] as? [[Any]]
        else { return }
      // 5
        let validWorks = works.compactMap { Spots(json: $0) }
      spots.append(contentsOf: validWorks)
    }
    
}

extension ViewController: MKMapViewDelegate {
  
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl) {
      let location = view.annotation as! Spots
      let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
      location.mapItem().openInMaps(launchOptions: launchOptions)
    }
    
}
