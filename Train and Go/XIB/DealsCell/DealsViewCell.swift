//
//  DealsViewCell.swift
//  Train and Go
//
//  Created by Loris Scandurra on 10/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import UIKit

class DealsViewCell: UITableViewCell {

    @IBOutlet weak var traveldateLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

