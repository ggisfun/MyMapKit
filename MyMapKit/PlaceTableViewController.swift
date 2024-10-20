//
//  PlaceTableViewController.swift
//  MyMapKit
//
//  Created by Adam Chen on 2024/10/19.
//

import UIKit
import MapKit

protocol PlaceTableViewControllerDelegate: AnyObject {
    func placeTableViewController(_ controller: PlaceTableViewController, didUpdateLocation selectedMapItem: MKMapItem)
}

class PlaceTableViewController: UITableViewController {

    weak var delegate: PlaceTableViewControllerDelegate?
    var mapItems = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaceCell")
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return mapItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)

        // Configure the cell...
        let mapItem = mapItems[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = mapItem.name
        content.secondaryText = mapItem.placemark.title
        cell.contentConfiguration = content

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mapItem = mapItems[indexPath.row]
        delegate?.placeTableViewController(self, didUpdateLocation: mapItem)
    }

}
