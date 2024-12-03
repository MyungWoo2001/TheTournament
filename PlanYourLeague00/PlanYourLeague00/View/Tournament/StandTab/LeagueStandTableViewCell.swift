//
//  LeagueStandTableViewCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/29/24.
//

import UIKit

class LeagueStandTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var rankLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var playsLabel: UILabel!
    @IBOutlet var difLabel: UILabel!
    @IBOutlet var ptsLabel: UILabel!
    @IBOutlet var logoImageView: UIImageView!

}
