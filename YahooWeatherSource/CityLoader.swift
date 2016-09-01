//
//  CityLoader.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct CityLoader {
	
	let queue: dispatch_queue_t// Async queue
	/**
	Construct a new city loader object
	*/
	public init() {
		queue = dispatch_queue_create("CityLoaderQueue", nil)
	}
	
	/**
	Search and load city information by city names. At the end of the function, the function bypasses calls to a delegate method
	- Parameter city: name of the city
	- Parameter province: province name where the city is
	- Parameter country: country name where the province is
	- Parameter complete: 
		A delegate method used to call at the end of the function.
		An array of JSON will be past to the complete
	*/
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
	
	/**
	Load city information by woeid. At the end of the function, the function bypasses calls to a delegate method
	
	- Parameter woeid:
		WOEID is an unique value used to locate a city
	- Parameter complete:
		A delegate method used to call at the end of the function.
		A city json will be loaded and past to the complete
		
		Once an error happened or no city is found from this woeid, a nil will be past to the complete
	*/
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

	/**
	Loads and updates the sunrise and sunset time of a city json
	- Parameter city: A json contains all the city information that needs to be updated
	- Parameter complete:
		A delegate method used to call at the end of the function.
		An updated city json will be past to the complete
		
		Once an error happened or no city is found from this woeid, a nil will be past to the complete
	*/
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
	
	/**
	Update the sunrise and sunset time by the WOEID
	- Parameter woeid: WOEID is a unique value used to locate a city
	- Parameter complete:
		A delegate method used to call at the end of the function.
		Sunrise and sunset, two NSDateComponents, will be past to the complete
		
		Once an error happened or no such city is found by the WOEID, two nils will be past
	*/
	public func updateTime(woeid woeid: String, complete: (sunrise: NSDateComponents?, sunset: NSDateComponents?) -> Void) {
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