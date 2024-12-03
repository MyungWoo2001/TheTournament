//
//  MatchDetailRowOneCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/11/24.
//

import UIKit

class MatchDetailRowOneCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var team1NameLabel: UILabel!
    @IBOutlet var team2NameLabel: UILabel!
    @IBOutlet var team1GoalLabel: UILabel!
    @IBOutlet var team2GoalLabel: UILabel!
    @IBOutlet var team1ImageView: UIImageView!
    @IBOutlet var team2ImageView: UIImageView!
    @IBOutlet var matchdateLabel: UILabel!

}
