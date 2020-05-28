//
//  CoudKitService.swift
//  Train and Go
//
//  Created by Loris Scandurra on 15/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitService {
    private static let singleton = CloudKitService()
    
    struct RecordType {
        static let Station = "Stations"
        static let Weather = "Weather"
        static let TripDay = "TripDay"
    }
    
    private init() {
    }
    
    func saveTrip(tripDay: TripDay, completion: @escaping (Result<TripDay ,Error>) -> ()) {
        let itemRecord = CKRecord(recordType: RecordType.TripDay)
        
        itemRecord["arrivalStation"] = tripDay.arrivalStation
        itemRecord["departureDate"] = tripDay.departureDate as Date
        itemRecord["departureStation"] = tripDay.departureStation
        itemRecord["price"] = tripDay.price as Double
        itemRecord["returnDate"] = tripDay.returnDate as Date
        
        CKContainer.default().publicCloudDatabase.save(itemRecord) { (record, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let record = record else {
                return
            }
            
            let returnTripDay = TripDay(
                arrivalStation: tripDay.arrivalStation,
                departureDate: tripDay.departureDate,
                departureStation: tripDay.departureStation,
                price: tripDay.price,
                returnDate: tripDay.returnDate,
                recordID: record.recordID)
            
            completion(.success(returnTripDay))
        }
    }
    
    func saveWeather(weather: Weather, completion: @escaping (Result<Weather ,Error>) -> ()) {
        let itemRecord = CKRecord(recordType: RecordType.Weather)
        
        itemRecord["date"] = weather.date as CKRecordValue
        itemRecord["temp_max"] = weather.temp_max as CKRecordValue
        itemRecord["temp_min"] = weather.temp_min as CKRecordValue
        itemRecord["weather_type"] = weather.weather_type as CKRecordValue
        itemRecord["station"] = weather.station
        
        CKContainer.default().publicCloudDatabase.save(itemRecord) { (record, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let record = record else {
                return
            }
            
            let returnWeather = Weather(
                date: weather.date,
                temp_max: weather.temp_max,
                temp_min: weather.temp_min,
                weather_type: weather.weather_type,
                station: weather.station,
                recordID: record.recordID,
                modificationDate: record.modificationDate)
            
            completion(.success(returnWeather))
        }
    }
    
    func truncateWeatherTable(completion: @escaping (Error) -> ()) {
        var recordIDs: [CKRecord.ID] = []
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.Weather, predicate: pred)
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 500
        queryOperation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                recordIDs.append(record.recordID)
            }
        }
        queryOperation.completionBlock = {
            print(recordIDs)
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
            CKContainer.default().publicCloudDatabase.add(deleteOperation)
        }
        
        CKContainer.default().publicCloudDatabase.add(queryOperation)
    }
    
    func truncateTripDayTable(completion: @escaping (Error) -> ()) {
        var recordIDs: [CKRecord.ID] = []
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.TripDay, predicate: pred)
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 115
        queryOperation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                recordIDs.append(record.recordID)
            }
        }
        queryOperation.completionBlock = {
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
            CKContainer.default().publicCloudDatabase.add(deleteOperation)
        }
        
        CKContainer.default().publicCloudDatabase.add(queryOperation)
    }
    
    func getBestDestinationStations(completion: @escaping (Result<Station, Error>) -> ()) {
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.Station, predicate: pred)
        query.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 5
        operation.desiredKeys = ["name", "lat", "lon", "score"]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                guard let name = record["name"] as? String else {
                    return
                }
                guard let lat = record["lat"] as? Double else {
                    return
                }
                guard let lon = record["lon"] as? Double else {
                    return
                }
                guard let score = record["score"] as? Double else {
                    return
                }
                let station = Station(name: name, lat: lat, lon: lon, score: score, recordID: record.recordID, modificationDate: record.modificationDate)
                completion(.success(station))
            }
        }
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func getFirstStation(completion: @escaping (Result<Station, Error>) -> ()) {
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.Station, predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = ["name", "lat", "lon", "score"]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                guard let name = record["name"] as? String else {
                    return
                }
                guard let lat = record["lat"] as? Double else {
                    return
                }
                guard let lon = record["lon"] as? Double else {
                    return
                }
                guard let score = record["score"] as? Double else {
                    return
                }
                let station = Station(name: name, lat: lat, lon: lon, score: score, recordID: record.recordID, modificationDate: record.modificationDate)
                completion(.success(station))
            }
        }
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func updateStation(station: Station, completion: @escaping (Result<Station, Error>) -> ()) {
        guard let recordID = station.recordID else {
            return
        }
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let record = record else {
                    return
                }
                record["score"] = station.score as CKRecordValue
                
                CKContainer.default().publicCloudDatabase.save(record, completionHandler: {(record, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        guard let record = record else {return}
                        guard let name = record["name"] as? String else {
                            return
                        }
                        guard let lat = record["lat"] as? Double else {
                            return
                        }
                        guard let lon = record["lon"] as? Double else {
                            return
                        }
                        guard let score = record["score"] as? Double else {
                            return
                        }
                        let station = Station(name: name, lat: lat, lon: lon, score: score, recordID: record.recordID, modificationDate: record.modificationDate)
                        completion(.success(station))
                    }
                })
            }
        })
    }
    
    func getStationWithNameompletion(stationName: String, completion: @escaping (Result<Station ,Error>) -> ()) {
        let pred = NSPredicate(format: "name = '\(stationName)'")
        let query = CKQuery(recordType: RecordType.Station, predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["name", "lat", "lon", "score"]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                guard let name = record["name"] as? String else {
                    return
                }
                guard let lat = record["lat"] as? Double else {
                    return
                }
                guard let lon = record["lon"] as? Double else {
                    return
                }
                guard let score = record["score"] as? Double else {
                    return
                }
                let station = Station(name: name, lat: lat, lon: lon, score: score, recordID: record.recordID, modificationDate: record.modificationDate)
                completion(.success(station))
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func getStationData(completion: @escaping (Result<Station ,Error>) -> ()) {
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.Station, predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["name", "lat", "lon", "score"]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                guard let name = record["name"] as? String else {
                    return
                }
                guard let lat = record["lat"] as? Double else {
                    return
                }
                guard let lon = record["lon"] as? Double else {
                    return
                }
                guard let score = record["score"] as? Double else {
                    return
                }
                let station = Station(name: name, lat: lat, lon: lon, score: score, recordID: record.recordID, modificationDate: record.modificationDate)
                completion(.success(station))
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func getTripDayData(departureStation: String ,completion: @escaping (Result<TripDay ,Error>) -> ()) {
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.TripDay, predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = [
            "arrivalStation",
            "departureDate",
            "departureStation",
            "price",
            "returnDate"]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                guard let arrivalStation = record["arrivalStation"] as? CKRecord.Reference else {
                    return
                }
                guard let departureDate = record["departureDate"] as? Date else {
                    return
                }
                guard let departureStation = record["departureStation"] as? CKRecord.Reference else {
                    return
                }
                guard let price = record["price"] as? Double else {
                    return
                }
                guard let returnDate = record["returnDate"] as? Date else {
                    return
                }
                let tripDay = TripDay(
                    arrivalStation: arrivalStation,
                    departureDate: departureDate,
                    departureStation: departureStation,
                    price: price,
                    returnDate: returnDate,
                    recordID: record.recordID)
                completion(.success(tripDay))
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func getWeatherData(station: String ,completion: @escaping (Result<Weather ,Error>) -> ()) {
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.Weather, predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = [
            "date",
            "station",
            "temp_max",
            "temp_min",
            "weather_type"]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                guard let date = record["date"] as? Date else {
                    return
                }
                guard let station = record["station"] as? CKRecord.Reference else {
                    return
                }
                guard let temp_max = record["temp_max"] as? Double else {
                    return
                }
                guard let temp_min = record["temp_min"] as? Double else {
                    return
                }
                guard let weather_type = record["weather_type"] as? Int64 else {
                    return
                }
                let weather = Weather(
                    date: date,
                    temp_max: temp_max,
                    temp_min: temp_min,
                    weather_type: weather_type,
                    station: station,
                    recordID: record.recordID,
                    modificationDate: record.modificationDate)
                completion(.success(weather))
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    static func getCloudKitService() -> CloudKitService {
        return singleton
    }
    
    func convertCKIDToCKReference(recordID: CKRecord.ID, action: CKRecord_Reference_Action) -> CKRecord.Reference {
        return CKRecord.Reference.init(recordID: recordID, action: action)
    }
    
    func getStationNameOf(tripStationReference: CKRecord.Reference, completion: @escaping (Result<String, Error>)-> Void){
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.Station, predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = [
            "name",
            "lat",
            "lon",
            "score",
            "modificationDate"
        ]
        
        operation.recordFetchedBlock = {record in
            DispatchQueue.main.async {
                
//                print("requesting name of the station called")
                
                guard let name = record["name"] as? String else {
                    return
                }
//                guard let lat = record["lat"] as? Double else {
//                    return
//                }
//                guard let lon = record["lon"] as? Double else {
//                    return
//                }
//                guard let score = record["score"] as? Double else {
//                    return
//                }
//                guard let modificationDate = record["modificationDate"] as? Date else {
//                    return
//                }
//
                if tripStationReference.self.recordID == record.recordID {
                    print("station name found: \(name)")
                    completion(.success(name))
                }
                
                
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
}

// MARK: Struct

struct Station {
    let name: String
    let lat: Double
    let lon: Double
    let score: Double
    let recordID: CKRecord.ID?
    let modificationDate: Date?
}

struct Weather {
    let date: Date
    let temp_max: Double
    let temp_min: Double
    let weather_type: Int64
    let station: CKRecord.Reference?
    var recordID: CKRecord.ID?
    let modificationDate: Date?
}

struct TripDay {
    let arrivalStation: CKRecord.Reference?
    let departureDate: Date
    let departureStation: CKRecord.Reference?
    let price: Double
    let returnDate: Date
    let recordID: CKRecord.ID?
}
