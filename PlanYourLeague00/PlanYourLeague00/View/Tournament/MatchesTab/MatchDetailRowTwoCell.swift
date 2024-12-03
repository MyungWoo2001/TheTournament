//
//  MatchDetailRowTwoCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/11/24.
//

import UIKit

class MatchDetailRowTwoCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet var matchSummaryLabel: UILabel!{
        didSet{
            matchSummaryLabel.numberOfLines = 0
        }
    }
    
}
