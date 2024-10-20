//
//  MapViewController.swift
//  MyMapKit
//
//  Created by Adam Chen on 2024/10/19.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var checkInButton: UIButton!
    @IBOutlet weak var drawRouteButton: UIButton!
    @IBOutlet var searchButtons: [UIButton]!
    
    let locationManager = CLLocationManager()
    let searchCompleter = MKLocalSearchCompleter()  // 用來提供自動完成建議
    var searchResults = [MKLocalSearchCompletion]() // 用來儲存搜尋建議
    var searchCompleterTableView: UITableView!
    
    var mapItems = [MKMapItem]()
    var selectedAnnotation: MKAnnotation?
    
    var container: NSPersistentContainer!
    var records = [Record]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkInButton.isHidden = true
        drawRouteButton.isHidden = true
        
        mapView.delegate = self

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        
        searchBar.delegate = self
        
        // 初始化 tableView 用於顯示自動完成結果
        searchCompleterTableView = UITableView()
        searchCompleterTableView.delegate = self
        searchCompleterTableView.dataSource = self
        searchCompleterTableView.isHidden = true // 預設隱藏
        view.addSubview(searchCompleterTableView)
        
        // 設定 searchCompleter 的 delegate
        searchCompleter.delegate = self
        searchCompleter.region = mapView.region // 初始時設定搜尋範圍為當前地圖範圍
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchCompleterTableView.frame = CGRect(x: 0, y: searchBar.frame.maxY, width: view.bounds.width, height: 300)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func goToCurrentLocation(_ sender: Any) {
        guard let userLocation = locationManager.location else { return }
        setLocation(userLocation.coordinate)
        view.endEditing(true)
    }
    
    func setLocation(_ coordinate: CLLocationCoordinate2D) {
        // 設定地圖的顯示範圍，將位置設為地圖中心
        let regionRadius: CLLocationDistance = 1000.0
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // 使用搜尋功能來顯示地點，限定範圍為當前地圖顯示區域
    func searchLocation(_ query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // 限制搜尋範圍為當前地圖顯示的區域
        let mapRegion = mapView.region
        request.region = MKCoordinateRegion(center: mapRegion.center, span: mapRegion.span)
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self, let response = response else {
                print("搜尋失敗: \(String(describing: error?.localizedDescription))")
                return
            }
            
            // 移除所有的地圖標註
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            // 將所有搜尋結果的地點顯示在地圖上
            var annotations = [CustomAnnotation]()
            for mapItem in response.mapItems {
                let annotation = CustomAnnotation (
                    coordinate: mapItem.placemark.coordinate,
                    title: mapItem.name,
                    subtitle: mapItem.placemark.title,
                    category: mapItem.pointOfInterestCategory?.rawValue
                )
                annotations.append(annotation)
            }
            
            self.mapView.addAnnotations(annotations)
            self.mapView.showAnnotations(annotations, animated: true)
            self.mapItems = response.mapItems
            self.dismiss(animated: true)
            self.performSegue(withIdentifier: "showPlaceSheet", sender: nil)
        }
    }
    
    @IBSegueAction func showPlaceSheet(_ coder: NSCoder) -> PlaceTableViewController? {
        let controller = PlaceTableViewController(coder: coder)
        controller?.delegate = self
        controller?.mapItems = mapItems
        
        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetPresentationController.largestUndimmedDetentIdentifier = .medium
            sheetPresentationController.detents = [
                .medium(),
                .large(),
                .custom(resolver: { context in
                    context.maximumDetentValue * 0.4
                })
            ]
        }
        
        return controller
    }
    
    @IBAction func quickSearch(_ sender: UIButton) {
        view.endEditing(true)
        mapView.removeOverlays(mapView.overlays)
        switch sender.tag {
        case 0:
            searchLocation("Restaurant")
        case 1:
            searchLocation("Coffee")
        case 2:
            searchLocation("Convenience Stores")
        case 3:
            searchLocation("Park")
        case 4:
            searchLocation("Hotel")
        case 5:
            searchLocation("Gas Station")
        default:
            break
        }
    }
    
    @IBAction func drawRoute(_ sender: Any) {
        guard let userLocation = locationManager.location else { return }
        guard selectedAnnotation != nil else { return }
        dismiss(animated: true)
        
        // 設置起點和終點
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: selectedAnnotation!.coordinate)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        // 計算路線
        calculateRoute(from: sourceMapItem, to: destinationMapItem)
    }
    
    // 計算路線
    func calculateRoute(from source: MKMapItem, to destination: MKMapItem) {
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = source
        directionsRequest.destination = destination
        directionsRequest.transportType = .automobile // 可以是 .walking, .transit 等
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { response, error in
            guard let response = response else {
                print("Error calculating directions: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.mapView.removeOverlays(self.mapView.overlays)
            
            // 繪製路線
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
            }
        }
    }
    
    @IBAction func checkIn(_ sender: Any) {
        guard selectedAnnotation != nil else { return }
        dismiss(animated: true)
        let place = selectedAnnotation?.title!
        let address = selectedAnnotation?.subtitle!
        let alertController = UIAlertController(title: place, message: address, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            let content = alertController.textFields?.first?.text
            guard let content else { return }
            guard content != "" else { return }
            self.save(place: place!, address: address!, content: content)
        }
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addTextField(configurationHandler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    func save(place: String, address: String, content: String) {
        let context = container.viewContext
        let record = Record(context: context)
        record.place = place
        record.address = address
        record.date = Date()
        record.content = content
        container.saveContext()
        
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//        let context = appDelegate.persistentContainer.viewContext
//        let record = Record(context: context)
//        record.place = place
//        record.address = address
//        record.date = Date()
//        record.content = content
//        appDelegate.saveContext()
    }

}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        setLocation(userLocation.coordinate)
    }
}

extension MapViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 當搜尋文字改變時，將文字傳遞給 searchCompleter 來獲取自動完成建議
        searchCompleter.queryFragment = searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text, !query.isEmpty {
            searchLocation(query)
            searchCompleterTableView.isHidden = true
        }
        searchBar.resignFirstResponder() // 收起鍵盤
    }
}

extension MapViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // 當自動完成建議更新時，將結果存入 searchResults 並重新載入 TableView
        searchResults = completer.results
        searchCompleterTableView.reloadData()
        searchCompleterTableView.isHidden = searchResults.isEmpty
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 當使用者點擊某個建議時，使用建議的完整文字進行搜尋
        let selectedSuggestion = searchResults[indexPath.row]
        searchLocation(selectedSuggestion.title)
        searchBar.text = selectedSuggestion.title
        searchCompleterTableView.isHidden = true // 隱藏建議列表
        searchBar.resignFirstResponder() // 收起鍵盤
    }
}

extension MapViewController: PlaceTableViewControllerDelegate {
    func placeTableViewController(_ controller: PlaceTableViewController, didUpdateLocation selectedMapItem: MKMapItem) {
        setLocation(selectedMapItem.placemark.coordinate)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        guard let customAnnotation = annotation as? CustomAnnotation else { return nil }
        
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.markerTintColor = .orange
                
        switch customAnnotation.category {
        case "MKPOICategoryRestaurant":
            annotationView.glyphImage = UIImage(systemName: "fork.knife")
        case "MKPOICategoryCafe":
            annotationView.glyphImage = UIImage(systemName: "cup.and.heat.waves.fill")
        case "MKPOICategoryFoodMarket":
            annotationView.glyphImage = UIImage(systemName: "storefront")
        case "MKPOICategoryHotel":
            annotationView.glyphImage = UIImage(systemName: "bed.double.fill")
        case "MKPOICategoryGasStation":
            annotationView.glyphImage = UIImage(systemName: "fuelpump.fill")
        case "MKPOICategoryNightlife":
            annotationView.glyphImage = UIImage(systemName: "wineglass.fill")
        case "MKPOICategoryPark":
            annotationView.glyphImage = UIImage(systemName: "tree")
        default:
            break
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        selectedAnnotation = annotation
        checkInButton.isHidden = false
        drawRouteButton.isHidden = false
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        selectedAnnotation = nil
        checkInButton.isHidden = true
        drawRouteButton.isHidden = true
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.link // 路徑顏色
            renderer.lineWidth = 4.0 // 路徑寬度
            return renderer
        }
        return MKOverlayRenderer()
    }
}
