import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
  
  //Outlets
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var getButton: UIButton!
  @IBOutlet weak var tagButton: UIButton!
  
  @IBOutlet weak var latitudeTextLabel: UILabel!
  @IBOutlet weak var longitudeTextLabel: UILabel!
  
  @IBOutlet weak var containerView: UIView!
    
  // LET and Variables
  let locationManager = CLLocationManager() // Will give the GPS coordinateds
  var location: CLLocation?
  var updatingLocation = false //p.535
  var lastLocationError: Error? //p.535
  let geocoder = CLGeocoder()
  var placemark: CLPlacemark?
  var performingReverseGeocoding = false
  var lastGeocodingError: Error?
  var timer: Timer? //s.557
  var managedObjectContext: NSManagedObjectContext! //s.640
  
  var logoVisible = false
  var soundID: SystemSoundID = 0
  
  // Lazys
  lazy var logoButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
    button.sizeToFit()
    button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
    button.center.x = self.view.bounds.midX
    button.center.y = 220
    return button
  }()
  
  /*
   OVERRIDES
   */
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    loadSoundEffect("Sound.caf")
  }
  
  // Will hide the navigation bar
 override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = false
  }
  
  // Mark: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TagLocation" {
      let controller = segue.destination as! LocationDetailsViewController
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      controller.managedObjectContext = managedObjectContext
    }
  }

  /*
   ACTIONS
   */
  
  @IBAction func getLocation() {
    let authStatus = CLLocationManager.authorizationStatus()    
    if authStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    
    if authStatus == .denied || authStatus == .restricted {
      showLocationServicesDeniedAlert()
      return
    }
    
    if logoVisible {
      hideLogoView()
    }
    
    if updatingLocation {
      stopLocationManager()
    } else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeocodingError = nil
      startLocationManager()
    }
    updateLabels()
  }
    

    /*
      FUNCTIONS
    */
 
  // MARK:- Helper Methods
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
  }
  
   // MARK:- UpdateLabels
  func updateLabels() {
    if let location = location {
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.isHidden = false
      messageLabel.text = ""
      latitudeTextLabel.isHidden = false //p.767
      longitudeTextLabel.isHidden = false //p.767
      // Show address
      if let placemark = placemark {
        addressLabel.text = string(from: placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
      
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      latitudeTextLabel.isHidden = true // p.767
      longitudeTextLabel.isHidden = true // p. 767

      let statusMessage: String
      if let error = lastLocationError as NSError? {
        if error.domain == kCLErrorDomain &&
          error.code == CLError.denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = ""
        showLogoView()
      }
      messageLabel.text = statusMessage
    }
    configureGetButton()
  }
  
  // MARK: - CLLocationManagerDelegate
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError \(error.localizedDescription)")
    
    if (error as NSError).code == CLError.locationUnknown.rawValue {
      return
    }
    lastLocationError = error
    stopLocationManager()
    updateLabels()
  }
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
        
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
        if let timer = timer {
            timer.invalidate()
        }
    }
  }
    
    @objc func didTimeOut() {
        print("*** Time out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
        }
    }

// Configure button
// Animation spinner added
  func configureGetButton() {
    let spinnerTag = 1000
    
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
      
      if view.viewWithTag(spinnerTag) == nil {
        let spinner = UIActivityIndicatorView(style: .white)
        spinner.center = messageLabel.center
        spinner.center.y += spinner.bounds.size.height/2 + 25
        spinner.startAnimating()
        spinner.tag = spinnerTag
        containerView.addSubview(spinner)
      }
    } else {
      getButton.setTitle("Get My Location", for: .normal)
      
      if let spinner = view.viewWithTag(spinnerTag) {
        spinner.removeFromSuperview()
      }
    }
  }

// Method s.552
    func string(from placemark: CLPlacemark) -> String {

      var line1 = ""
      line1.add(text: placemark.subThoroughfare)
      line1.add(text: placemark.thoroughfare, separetedBy: " ")
      
      var line2 = ""
      line2.add(text: placemark.locality)
      line2.add(text: placemark.administrativeArea, separetedBy: " ")
      line2.add(text: placemark.postalCode, separetedBy: " ")
      
      line1.add(text: line2, separetedBy: "\n")
      return line1
    }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    // 1
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
    
    // 2
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    // New section #1 This calculates the distance between the new reading and the previous reading, if there was one.
    var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
    if let location = location {
        distance = newLocation.distance(from: location)
    }
    
    // 3
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      lastLocationError = nil
      location = newLocation
      
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        print("*** We're done!")
        stopLocationManager()
        // New section #2 This forces a reverse geocoding for the final location, even if the app is already currently performing another geocoding request.
        if distance > 0 {
            performingReverseGeocoding = false
        }
        // End of new section #2
        
      }
      updateLabels()
      if !performingReverseGeocoding {
        print("*** Going to geocode")
        performingReverseGeocoding = true
        
        geocoder.reverseGeocodeLocation(newLocation,completionHandler: {
          placemarks, error in
          self.lastGeocodingError = error
          if error == nil, let p = placemarks, !p.isEmpty {
            // New Code block
            if self.placemark == nil {
              print("FIRST TIME!")
              self.playSoundEffect()
            }
            self.placemark = p.last!
          } else {
            self.placemark = nil
          }
            
          self.performingReverseGeocoding = false
          self.updateLabels()
          })
        }
            // New section #3
      } else if distance < 1 {
        let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
        if timeInterval > 10 {
            print("*** Force done!")
            stopLocationManager()
            updateLabels()
        }
      }
    }
  // This hides the container view so the labels disappears and puts logoButton object to the screen.
  func showLogoView() {
    if !logoVisible {
      logoVisible = true
      containerView.isHidden = true
      view.addSubview(logoButton)
    }
  }
  
  func hideLogoView() {
    if !logoVisible { return }
    
    logoVisible = false
    containerView.isHidden = false
    containerView.center.x = view.bounds.size.width * 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    let centerX = view.bounds.midX
    
    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = CAMediaTimingFillMode.forwards
    panelMover.duration = 0.6
    panelMover.fromValue = NSValue(cgPoint: containerView.center)
    panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    panelMover.delegate = self
    containerView.layer.add(panelMover, forKey: "panelMover")
    
    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = CAMediaTimingFillMode.forwards
    logoMover.duration = 0.5
    logoMover.fromValue = NSValue(cgPoint: logoButton.center)
    logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    logoButton.layer.add(logoMover, forKey: "logoMover")
    
    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = CAMediaTimingFillMode.forwards
    logoRotator.duration = 0.5
    logoRotator.fromValue = 0.0
    logoRotator.toValue = -2 * Double.pi
    logoRotator.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotator")
    
  }
  
  // Mark: - Animation Delegate Methods
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    containerView.layer.removeAllAnimations()
    containerView.center.x = view.bounds.size.width / 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    logoButton.layer.removeAllAnimations()
    logoButton.removeFromSuperview()
  }
  
  // Mark: - Sound effects
  func loadSoundEffect(_ name: String) {
    if let path = Bundle.main.path(forResource: name, ofType: nil) {
      let fileURL = URL(fileURLWithPath: path, isDirectory: false)
      let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
      if error != kAudioServicesNoError {
        print("Error code \(error) loading sound: \(path)")
      }
    }
  }
  
  func unloadSoundEffect() {
    AudioServicesDisposeSystemSoundID(soundID)
    soundID = 0
  }
  
  func playSoundEffect() {
    AudioServicesPlaySystemSound(soundID)
  }
  
} // Class ends
