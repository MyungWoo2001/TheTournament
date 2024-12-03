//
//  SearchTableViewCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/23/24.
//

import UIKit

class SearchTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var nameLabel: UILabel! {
        didSet {
            nameLabel.adjustsFontForContentSizeCategory = true
        }
    }
    @IBOutlet var managerLabel: UILabel! {
        didSet {
            managerLabel.adjustsFontForContentSizeCategory = true
        }
    }
    @IBOutlet var summaryLabel: UILabel! {
        didSet {
            summaryLabel.adjustsFontForContentSizeCategory = true
        }
    }
    //@IBOutlet var contactLagel: UILabel!
    //@IBOutlet var managerLabel: UILabel!
    //@IBOutlet var summaryLabel: UILabel!
    @IBOutlet var thumbnailImageView: UIImageView! {
        didSet {
            thumbnailImageView.layer.cornerRadius = 20.0
            thumbnailImageView.clipsToBounds = true
        }
    }

}
