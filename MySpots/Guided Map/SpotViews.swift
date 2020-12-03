import Foundation
import MapKit

class SpotsMarkerView: MKMarkerAnnotationView {
  override var annotation: MKAnnotation? {
    willSet {
      guard let spots = newValue as? Spots else { return }
      canShowCallout = true
      calloutOffset = CGPoint(x: -5, y: 5)
      rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
      markerTintColor = spots.markerTintColor
//      glyphText = String(spots.discipline.first!)
        
        // Adds glyph
        if let imageName = spots.imageName {
          glyphImage = UIImage(named: imageName)
        } else {
          glyphImage = nil
        }
    }
  }
}
