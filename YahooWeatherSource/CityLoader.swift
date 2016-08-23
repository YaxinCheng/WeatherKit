//
//  CityLoader.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct CityLoader: WeatherSourceProtocol {

	public init() {
	}
	
	public func loadCity(cityName: String, complete: ([NSDictionary]) -> Void) {
		let baseSQL: WeatherSourceSQLPatterns = .city
		let sql = baseSQL.generateSQL(with: cityName)
		sendRequst(sql) {
			guard let citiesJSON = $0 as? NSDictionary else {
				complete([])
				return
			}
			let unwrapped: [NSDictionary]
			if let places = (citiesJSON["query"] as? NSDictionary)?["results"]?["place"] as? [NSDictionary] {
				unwrapped = places
			} else if let place = (citiesJSON["query"] as? NSDictionary)?["results"]?["place"] as? NSDictionary {
				unwrapped = [place]
			} else {
				complete([])
				return
			}
			complete(unwrapped)
		}
	}
	
	
	public func daytime(for city: NSDictionary, complete: (NSDictionary?) -> Void) {
		guard let woeid = city["woeid"] as? String else { return }
		updateTime(woeid: woeid) {
			guard $0 != nil && $1 != nil else {
				complete(nil)
				return
			}
			var cityDictionary: Dictionary<String, AnyObject> = city as! Dictionary<String, AnyObject>
			cityDictionary["sunrise"] = $0
			cityDictionary["sunset"] = $1
			complete(cityDictionary)
		}
	}
	
	public func updateTime(woeid woeid: String, complete: (sunrise: NSDateComponents?, sunset: NSDateComponents?) -> Void ) {
		let baseSQL = WeatherSourceSQLPatterns.daytime
		let sql = baseSQL.generateSQL(with: woeid)
		sendRequst(sql) {
			guard
				let daytimeJSON = $0 as? NSDictionary,
				let unwrapped = ((daytimeJSON["query"] as? NSDictionary)?["results"]?["channel"] as? NSDictionary)?["astronomy"] as? NSDictionary,
				let sunriseString = unwrapped["sunrise"] as? String,
				let sunrise = NSDateComponents(from: sunriseString),
				let sunsetString = unwrapped["sunset"] as? String,
				let sunset = NSDateComponents(from: sunsetString)
			else {
				complete(sunrise: nil, sunset: nil)
				return
			}
			complete(sunrise: sunrise, sunset: sunset)
		}
	}
}