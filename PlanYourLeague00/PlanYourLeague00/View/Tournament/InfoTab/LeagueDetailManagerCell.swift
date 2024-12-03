//
//  LeagueDetailManagerCell.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/24/24.
//

import UIKit

class LeagueDetailManagerCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet var leagueManagerNameLabel: UILabel!{
        didSet {
            leagueManagerNameLabel.numberOfLines = 0
        }
    }
    @IBOutlet var leagueManagerPhoneLabel: UILabel! {
        didSet {
            leagueManagerPhoneLabel.numberOfLines = 1
        }
    }
    @IBOutlet var leagueManagerEmailLabel: UILabel! {
        didSet {
            leagueManagerEmailLabel.numberOfLines = 1
        }
    }

}

class LeagueDetailCreateNewLeagueCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet var label: UILabel!
    
}
