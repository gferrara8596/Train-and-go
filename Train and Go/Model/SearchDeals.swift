//
//  SearchDeals.swift
//  Train and Go
//
//  Created by Loris Scandurra on 10/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import UIKit

class SearchDeals: NSObject {
    
    private static let singleton = SearchDeals()
    let servicelocator = ServiceLocator.getServiceLocator()
    
    private override init() {}
    
    func findDeals(completion: @escaping (Result<[TripDay], Error>) -> ()) {
//        checkStationScoreStatus(completion: {
//            result in
//            switch result {
//            case .success(let stationScoreUpdateNeeded):
//                if stationScoreUpdateNeeded {
//                    self.updateStationScore()
//                }
//            case .failure(let error):
//                print(error)
//            }
//        })
        var tripDays: [TripDay] = []
//        servicelocator.getCloudKitService().getStationData(completion: {
//            result in
//            switch result {
//            case .success(let station):
//                self.requestWeatherOf(station: station)
//            case .failure(let error):
//                print("error")
//            }
//        })
        servicelocator.getCloudKitService().getBestDestinationStations(completion: {result in
            switch result {
            case .success(let station):
                self.searchTrips(destinationStation: station, completion: {result in
                    switch result {
                    case .success(let tripday):
                        tripDays.append(tripday)
                        if tripDays.count == 5 {
                            completion(.success(tripDays))
                        }
                    case .failure(let error):
                        print(error)
                    }
                })
            case .failure(let error):
                print(error)
            }
        })
    }
    
    private func checkStationScoreStatus(completion: @escaping (Result<Bool, Error>) -> ()) {
        servicelocator.getCloudKitService().getFirstStation(completion: {(result) in
            switch result {
            case .success(let station):
                if (station.modificationDate?.compare(Date()))!.rawValue > 86400 {
                    completion(.success(true))
                }
            case .failure(let error):
                print(error)
            }
        })
    }
    
    private func updateStationScore() {
        servicelocator.getCloudKitService().getStationData(completion: {(result) in
            switch result {
            case .success(let station):
                self.requestWeatherOf(station: station)
            case .failure(let error):
                print(error)
            }
        })
    }
        
    private func requestWeatherOf(station: Station) {
        servicelocator.getWeatherAPI().loadFiveDaysWeather(withCoord: station.lon, lat: station.lat, completion: {weatherForecast in
            let filteredWeatherForecast = self.oneWeatherForecastPerDay(weatherForecast: weatherForecast)
            let score = self.scoreWeather(weatherInfo: filteredWeatherForecast)
            let updatedStation = Station(
                name: station.name,
                lat: station.lat,
                lon: station.lon,
                score: score,
                recordID: station.recordID,
                modificationDate: nil
            )
            self.saveWeatherToIcloud(weatherForecast: filteredWeatherForecast, station: station)
            
            self.servicelocator.getCloudKitService().updateStation(station: updatedStation, completion: {result in
            })
        })
    }
    
    private func oneWeatherForecastPerDay(weatherForecast: OpenWeatherFiveDayForecast) -> OpenWeatherFiveDayForecast {
        var filteredWeatherList: [OpenWeatherList] = []
        for weather in weatherForecast.list {
            if weather.dt_txt.contains("12:00:00") {
                filteredWeatherList.append(weather)
            }
        }
        return OpenWeatherFiveDayForecast(list: filteredWeatherList)
    }
    
    private func saveWeatherToIcloud(weatherForecast: OpenWeatherFiveDayForecast, station: Station) {
        for weather in weatherForecast.list {
            let iCloudWeather = Weather(
                date: Date(timeIntervalSince1970: TimeInterval(weather.dt)),
                temp_max: weather.main.temp_max,
                temp_min: weather.main.temp_min,
                weather_type: Int64(weather.weather[0].id),
                station: servicelocator.getCloudKitService().convertCKIDToCKReference(recordID: station.recordID!, action: .none),
                modificationDate: nil)
            servicelocator.getCloudKitService().saveWeather(weather: iCloudWeather, completion: {(weather) in})
        }
    }
        
    private func scoreWeather(weatherInfo: OpenWeatherFiveDayForecast) -> Double {
        var score: Double = 0
        for weathers in weatherInfo.list {
            for weather in weathers.weather {
                if weather.id > 800 {
                    score = score + 0.5
                } else  if weather.id == 800 {
                    score = score + 1
                }
            }
        }
        return score
    }
    
    private func searchTrips(destinationStation: Station, completion: @escaping (Result<TripDay, Error>) -> ()) {
        let tomorrow = Date().addingTimeInterval(86400)
        let maxReturnDate = Date().addingTimeInterval(86400*3)
        
        servicelocator.getTreniItaliaAPI().searchPrices(
            from: "Napoli Centrale",
            to: destinationStation.name,
            startDate: tomorrow,
            returnDate: maxReturnDate,
            completion: {
                trips in
                let sortedDepartureTrips = trips.sorted(by: {
                    $0.Price < $1.Price
                })
                self.servicelocator.getTreniItaliaAPI().searchPrices(
                    from: destinationStation.name,
                    to: "Napoli Centrale",
                    startDate: maxReturnDate,
                    returnDate: maxReturnDate,
                    completion: {trips in
                        let sortedReturnTrips = trips.sorted(by: {
                            $0.Price < $1.Price
                        })
                        if sortedDepartureTrips.count > 0 || sortedReturnTrips.count > 0 {
                            self.saveTripToICloud(departureTrip: sortedDepartureTrips[0], returnTrip: sortedReturnTrips[0], station: destinationStation, completion: {result in
                                switch result {
                                case .success(let tripDay):
                                    completion(.success(tripDay))
                                case .failure(let error):
                                    print(error)
                                }
                            })
                        } else {
                            print(destinationStation.name)
                        }
                })
        })
    }
    
    private func saveTripToICloud(departureTrip: Trip, returnTrip: Trip, station: Station, completion: @escaping (Result<TripDay, Error>) -> ()) {
        servicelocator.getCloudKitService().getStationWithNameompletion(stationName: "NAPOLI CENTRALE", completion: {result in
            switch result {
            case .success(let fixStation):
                let tripDay = TripDay(
                    arrivalStation:
                    self.servicelocator.getCloudKitService().convertCKIDToCKReference(recordID: station.recordID!, action: .none),
                    departureDate: departureTrip.DepartureTime,
                    departureStation: self.servicelocator.getCloudKitService().convertCKIDToCKReference(recordID: fixStation.recordID!, action: .none),
                    price: departureTrip.Price + returnTrip.Price,
                    returnDate: returnTrip.DepartureTime,
                    recordID: nil)
                self.servicelocator.getCloudKitService().saveTrip(tripDay: tripDay, completion: {
                    result in
                    switch result {
                    case .success(let tripDay):
                        completion(.success(tripDay))
                    case .failure(let error):
                        print(error)
                    }
                })
            case .failure(let error):
                print(error)
            }
            
        })
    }
    
        static func getSerachDeals() -> SearchDeals {
            return singleton
        }
        
    }

struct StationWithWeather {
    var stationInfo: Station?
    var weatherInfo: OpenWeatherFiveDayForecast?
    var weatherScore: Double = 0.0
}
