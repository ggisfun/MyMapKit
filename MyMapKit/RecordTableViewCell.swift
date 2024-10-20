//
//  RecordTableViewCell.swift
//  MyMapKit
//
//  Created by Adam Chen on 2024/10/20.
//

import UIKit

class RecordTableViewCell: UITableViewCell {

    static let identifier: String = "RecordTableViewCell"
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
