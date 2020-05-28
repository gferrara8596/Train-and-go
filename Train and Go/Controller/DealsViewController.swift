//
//  DealsViewController.swift
//  Train and Go
//
//  Created by Loris Scandurra on 10/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import UIKit
import CloudKit

class DealsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var trips: [TripDay] = []
    let servicelocator = ServiceLocator.getServiceLocator()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let date = Date().addingTimeInterval(86400)
//        print(date)
//        servicelocator.getCloudKitService().truncateTripDayTable(completion: {
//            result in
//        })
//        servicelocator.getCloudKitService().truncateWeatherTable(completion: {
//            result in
////        })
        SearchDeals.getSerachDeals().findDeals(completion: {result in
            switch result {
            case .success(let tripDay):
                self.trips = tripDay
                print("data loaded from apis")
            case .failure(let error):
                print(error)
            }
        })

        servicelocator.getCloudKitService().getTripDayData(departureStation: "NAPOLI CENTRALE", completion: {(result) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let tripDay):
                self.trips.append(tripDay)
                self.tableView.reloadData()
                print("data loaded from cloud")
            }
        })

        let dealsViewCell = UINib(nibName: "DealsViewCell", bundle: nil)
        tableView.register(dealsViewCell, forCellReuseIdentifier: "DealsViewCell")
               
    }

}

extension DealsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if trips.count != 0 && indexPath.row < trips.count-1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DealsViewCell") as! DealsViewCell
            servicelocator.getCloudKitService().getStationNameOf(tripStationReference: trips[indexPath.row].arrivalStation!, completion: { name in
                switch name {
                case .success(let name):
                    cell.cityLabel.text = name
                    print("station name: \(name)")
                    cell.contentView.addSubview(cell.cityLabel)
                case .failure(let error):
                    print("error in cloudkit: \(error)")
                }
            })
            cell.priceLabel.text = String(trips[indexPath.row].price) + " €"
            cell.priceLabel.text = String(trips[indexPath.row].price) + " €"
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMMM"
            let departureDateString = formatter.string(from: trips[indexPath.row].departureDate)
            let returnDateString = formatter.string(from: trips[indexPath.row].returnDate)
            cell.traveldateLabel.text = "from \(departureDateString) to \(returnDateString)"
            return cell
        }
            
        return UITableViewCell.init()
    }
    


}


