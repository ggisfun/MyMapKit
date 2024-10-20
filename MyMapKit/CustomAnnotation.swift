//
//  CustomAnnotation.swift
//  MyMapKit
//
//  Created by Adam Chen on 2024/10/19.
//
import Foundation
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    // 自訂屬性
    var category: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, category: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.category = category
    }
}

