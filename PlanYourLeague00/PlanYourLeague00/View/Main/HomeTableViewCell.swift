//
//  HomeTableViewCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/9/24.
//

import UIKit

class HomeTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet var leagueNameLabel: UILabel!
    @IBOutlet var team1logo: UIImageView! {
        didSet {
            team1logo.layer.cornerRadius = 10.0
            team1logo.clipsToBounds = true
        }
    }
    @IBOutlet var team1NameLabel: UILabel! {
        didSet {
            team1NameLabel.numberOfLines = 0
        }
    }
    @IBOutlet var team1GoalLabel: UILabel!
    
    @IBOutlet var team2Logo: UIImageView! {
        didSet {
            team2Logo.layer.cornerRadius = 10.0
            team2Logo.clipsToBounds = true
        }
    }
    @IBOutlet var team2NameLabel: UILabel!{
        didSet {
            team2NameLabel.numberOfLines = 0
        }
    }
    @IBOutlet var team2GoalLabel: UILabel!
    
    @IBOutlet var dateLabel: UILabel!

}
