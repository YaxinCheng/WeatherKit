//
//  CityLoader.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct CityLoader {
	
	let queue: dispatch_queue_t
	public init() {
		queue = dispatch_queue_create("CityLoaderQueue", nil)
	}
	
	public func loadCity(city cityName: String, province: String = "", country: String = "", complete: ([Dictionary<String, AnyObject>]) -> Void) {
		typealias JSON = Dictionary<String, AnyObject>
		dispatch_async(queue) {
			let baseSQL: WeatherSourceSQL = .cityFromName
			baseSQL.execute(information: cityName + ", " + province + ", " + country) { result in
				switch result {
				case .Success(let citiesJSON):
					let unwrapped: [JSON]
					if let places = (citiesJSON["query"]?["results"] as? JSON)?["place"] as? [JSON] {
						unwrapped = places
					} else if let place = (citiesJSON["query"]?["results"] as? JSON)?["place"] as? JSON {
						unwrapped = [place]
					} else {
						dispatch_async(dispatch_get_main_queue()) {
							complete([])
						}
						return
					}
					dispatch_async(dispatch_get_main_queue()) {
						complete(unwrapped)
					}
				case .Failure(_):
					complete([])
				}
			}
		}
	}
	
	
	public func loadCity(woeid woeid: String, complete: (Dictionary<String, AnyObject>?) -> Void) {
		typealias JSON = Dictionary<String, AnyObject>
		dispatch_async(queue) {
			let baseSQL: WeatherSourceSQL = .cityFromWoeid
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .Success(let json):
					guard let unwrapped = (json["query"]?["results"] as? JSON)?["place"] as? JSON else {
						dispatch_async(dispatch_get_main_queue()) {
							complete(nil)
						}
						return
					}
					dispatch_async(dispatch_get_main_queue()) {
						complete(unwrapped)
					}
				case .Failure(_):
					complete(nil)
				}
			}
		}
	}

	
	public func daytime(for city: Dictionary<String, AnyObject>, complete: (Dictionary<String, AnyObject>?) -> Void) {
		dispatch_async(queue) {
			guard let woeid = city["woeid"] as? String else { return }
			self.updateTime(woeid: woeid) {
				guard $0 != nil && $1 != nil else {
					dispatch_async(dispatch_get_main_queue()) {
						complete(nil)
					}
					return
				}
				var cityDictionary: Dictionary<String, AnyObject> = city
				cityDictionary["sunrise"] = $0
				cityDictionary["sunset"] = $1
				complete(cityDictionary)
			}
		}
	}
	
	public func updateTime(woeid woeid: String, complete: (sunrise: NSDateComponents?, sunset: NSDateComponents?) -> Void ) {
		dispatch_async(queue) {
			let baseSQL: WeatherSourceSQL = .daytime
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .Success(let daytimeJSON):
					guard
						let unwrapped = (daytimeJSON["query"]?["results"] as? Dictionary<String, AnyObject>)?["channel"]?["astronomy"] as? Dictionary<String, AnyObject>,
						let sunriseString = unwrapped["sunrise"] as? String,
						let sunrise = NSDateComponents(from: sunriseString),
						let sunsetString = unwrapped["sunset"] as? String,
						let sunset = NSDateComponents(from: sunsetString)
						else {
							dispatch_async(dispatch_get_main_queue()) {
								complete(sunrise: nil, sunset: nil)
							}
							return
					}
					dispatch_async(dispatch_get_main_queue()) {
						complete(sunrise: sunrise, sunset: sunset)
					}
				case .Failure(_):
					complete(sunrise: nil, sunset: nil)
				}
			}
		}
	}
}