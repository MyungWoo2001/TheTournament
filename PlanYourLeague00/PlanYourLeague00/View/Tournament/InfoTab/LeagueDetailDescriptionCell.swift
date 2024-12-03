//
//  LeagueDetailDescriptionCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/23/24.
//

import UIKit

class LeagueDetailDescriptionCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var summaryLabel: UILabel!{
        didSet {
            summaryLabel.numberOfLines = 0
        }
    }
    
    
}
