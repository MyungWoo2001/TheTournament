//
//  MatchesTableViewCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/5/24.
//

import UIKit

class MatchesTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var team1Label: UILabel!
    @IBOutlet var team2label: UILabel!
    @IBOutlet var goal1Label: UILabel!
    @IBOutlet var goal2Label: UILabel!
    @IBOutlet var matchDateLabel: UILabel!
    @IBOutlet var logo1ImageView: UIImageView!
    @IBOutlet var logo2ImageView: UIImageView!

}
