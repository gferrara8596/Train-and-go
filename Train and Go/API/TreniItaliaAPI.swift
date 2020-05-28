//
//  TreniItaliaAPI.swift
//  Train and Go
//
//  Created by Loris Scandurra on 10/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import UIKit

class TreniItaliaAPI: NSObject {
    
    private static let singleton = TreniItaliaAPI()
    var notificationTrip = Notification(name: Notification.Name("TripReady"))
    private override init() {
        
    }
    
    func searchPrices(from: String, to: String, startDate: Date, returnDate: Date, completion: @escaping ([Trip]) -> ()) {
        let flag = "A"
        let dayDateFormat = DateFormatter()
        dayDateFormat.dateFormat = "dd/MM/yyyy"
        let aDate = dayDateFormat.string(from: startDate)
        print(aDate)
        let rDate = dayDateFormat.string(from: returnDate)
        let aTime = 0
        let rTime = 0
        let adultNum = 1
        let childNum = 0
        let direction = "AR"
        let onlyRegional = false
        let frecce = false
        var trips: [Trip] = []
        
        let decoder = JSONDecoder()
        let session = URLSession(configuration: URLSessionConfiguration.default,delegate: nil, delegateQueue: OperationQueue.main)
        
        
        let endpoint = "https://www.lefrecce.it/msite/api/solutions?origin=\(from)&destination=\(to)&arflag=\(flag)&adate=\(aDate)&atime=\(aTime)&rdate=\(rDate)&rtime=\(rTime)&adultno=\(adultNum)&childno=\(childNum)&direction=\(direction)&frecce=\(frecce)&onlyRegional=\(onlyRegional)&offset=1"
        
        
        let safeUrlString = endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        guard let endpointUrl = URL(string: safeUrlString!) else {
            print("error in the url ")
            return
        }
        
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in guard let jsonData = data else {
            print("invalid payload")
            return
            }
            do {
                let trainConnections = try decoder.decode([TrainTicketInfo].self, from: jsonData)
                
                for trainConnection in trainConnections {
                    let trip: Trip = Trip(
                        departureStation: from,
                        arrivalStation: to,
                        DepartureTime: Date(timeIntervalSince1970: trainConnection.departuretime),
                        Price: trainConnection.minprice
                    )
                    
                    trips.append(trip)
                
                }
                completion(trips)
                
            } catch let error {
                print("Unable to decode json: \(error)")
            }
        }
        
        dataTask.resume()
    }
    
    static func getTrenItaliaAPI() -> TreniItaliaAPI {
        return singleton
    }
    
    private func stringDurationInSeconds(duration: String) -> Int {
        let hhString = duration.prefix(2)
        let mmString = duration.suffix(2)
        let hhInt = (hhString as NSString).integerValue
        let mmInt = (mmString as NSString).integerValue
        
        let durationInInt = hhInt * 3600 + mmInt * 60
        
        return durationInInt
        
    }
    
}

struct Trip {
    let departureStation: String
    let arrivalStation: String
    let DepartureTime: Date
    let Price: Double
}

struct TrainTicketInfo: Codable {
    var idsolution: String
    var origin: String
    var destination: String
    var direction: String
    var departuretime: TimeInterval
    var arrivaltime: TimeInterval
    var minprice: Double
    var duration: String
    var changesno: Int
    var bookable: Bool
    var saleable: Bool
    var onlycustom: Bool
    var showseat: Bool?
}
