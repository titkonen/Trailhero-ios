import Foundation
import MapKit
import Contacts

class Spots: NSObject, MKAnnotation {
  let title: String?
  let locationName: String
  let discipline: String
  let coordinate: CLLocationCoordinate2D
  
    // markerTintColor for disciplines: Jumps, Rolleys, Drops etc...
    var markerTintColor: UIColor  {
      switch discipline {
      case "Jumps":
        return .red
      case "Dirts":
        return .orange
      case "Obstacles":
        return .blue
      case "Steps":
        return .purple
      case "Rolleys":
          return .gray
      case "FlowLines":
          return .green
      case "BikeParks":
        return .cyan
      case "Drops":
        return .black
      default:
        return .lightGray
      }
    }
    // add glyph image instead of text
    var imageName: String? {
      if discipline == "Jumps" {
        return "Jumps"
      }
      if discipline == "Dirts" {
        return "Dirts"
      }
      if discipline == "Obstacles" {
        return "Obstacles"
      }
      if discipline == "Steps" {
        return "Steps"
      }
      if discipline == "Rolleys" {
        return "Rolleys"
      }
      if discipline == "FlowLines" {
        return "FlowLines"
      }
      if discipline == "BikeParks" {
        return "BikeParks"
      }
      if discipline == "Drops" {
        return "Drops"
      }
    
      return "Obstacles"
    }
    
  init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
    self.title = title
    self.locationName = locationName
    self.discipline = discipline
    self.coordinate = coordinate
    
    super.init()
  }
    
    // Mark: - JSON Initializer
    init?(json: [Any]) {
      // 1
      self.title = json[2] as? String ?? "No Title"
      self.locationName = json[3] as! String
      self.discipline = json[1] as! String
      // 2 5=19, 4=18, 3=16, 2=15, 1=12
      if let latitude = Double(json[4] as! String),
        let longitude = Double(json[5] as! String) {
      self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      } else {
        self.coordinate = CLLocationCoordinate2D()
      }
    }
  
  var subtitle: String? {
    return locationName
  }
    
    // Annotation right callout accessory opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
      let addressDict = [CNPostalAddressStreetKey: subtitle!]
      let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
      let mapItem = MKMapItem(placemark: placemark)
      mapItem.name = title
      return mapItem
    }
    
    
}
