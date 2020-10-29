//
//  JobTableViewCell.swift
//  
//
//  Created by Ateeb Ahmed on 13/05/2019.
//

import UIKit

class JobTableViewCell: UITableViewCell {

    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var whenLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!

    var from: String? {
        didSet {
            fromLabel.text = from
        }
    }
    var to: String? {
        didSet {
            toLabel.text = to
        }
    }
    var when: String? {
        didSet {
            whenLabel.text = when
        }
    }
    var type: String? {
        didSet {
            typeLabel.text = type
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
