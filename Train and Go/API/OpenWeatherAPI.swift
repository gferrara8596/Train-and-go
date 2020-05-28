//
//  OpenWeatherAPI.swift
//  Train and Go
//
//  Created by Loris Scandurra on 10/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import UIKit



class OpenWeatherAPI {
    
    private static let singleton = OpenWeatherAPI()
    let key = "75f183c4bf1e6eb3dc1d621f0732ec3b"
    
    private init() {}
    
    func loadFiveDaysWeather(withCoord lon: Double, lat: Double, completion: @escaping (OpenWeatherFiveDayForecast) -> Void) {
        let session = URLSession(configuration: URLSessionConfiguration.default,delegate: nil, delegateQueue: OperationQueue.main)
        let endpoint = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&units=metric&appid=\(key)"
        let safeUrlString = endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let endpointUrl = URL(string: safeUrlString!) else {
            print("Invalid url for load weather")
            return
        }
        
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let jsonData = data else {
                print("invalid payload in weather json")
                return
            }
            let decoder = JSONDecoder()
            do {
                let weatherForecast = try decoder.decode(OpenWeatherFiveDayForecast.self, from: jsonData)
                completion(weatherForecast)
            } catch let error {
                print("weather json decode failed: \(error)")
            }
        }
        dataTask.resume()
    }
    
    
    static func getOpenWeatherAPI() -> OpenWeatherAPI {
        return singleton
    }
    
}

struct OpenWeatherFiveDayForecast: Codable {
    let list: [OpenWeatherList]
}

struct OpenWeatherWeather: Codable {
    let id: Int
}

struct OpenWeatherList: Codable {
    let dt: Int
    let main: Main
    let weather: [OpenWeatherWeather]
    let dt_txt: String
}

struct Main: Codable {
    let temp: Double
    let temp_min: Double
    let temp_max: Double
}


