//
//  LeagueDetailInfoCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/24/24.
//

import UIKit

class LeagueDetailInfoCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var leagueNameLabel: UILabel! {
        didSet {
            leagueNameLabel.numberOfLines = 0
        }
    }
    @IBOutlet var leagueSportLabel: UILabel!
  


}
