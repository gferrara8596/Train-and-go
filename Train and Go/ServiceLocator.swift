//
//  ServiceLocator.swift
//  Train and Go
//
//  Created by Loris Scandurra on 10/01/2020.
//  Copyright © 2020 Loris Scandurra. All rights reserved.
//

import UIKit

class ServiceLocator: NSObject {

    private static let singleton = ServiceLocator()
    private let weatherAPI = OpenWeatherAPI.getOpenWeatherAPI()
    private let treniItaliaAPI = TreniItaliaAPI.getTrenItaliaAPI()
    private let cloudKitService = CloudKitService.getCloudKitService()
    
    private override init() {
        
    }
    
    static func getServiceLocator() -> ServiceLocator {
        return singleton
    }
    
    func getWeatherAPI() -> OpenWeatherAPI {
        return weatherAPI
    }
    
    func getTreniItaliaAPI() -> TreniItaliaAPI {
        return treniItaliaAPI
    }
    
    func getCloudKitService() -> CloudKitService {
        return cloudKitService
    }
    
}

