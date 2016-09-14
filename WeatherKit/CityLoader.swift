//
//  CityLoader.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

public struct CityLoader {
	
	let queue: DispatchQueue// Async queue
	/**
	Construct a new city loader object
	*/
	public init() {
		queue = DispatchQueue(label: "CityLoaderQueue", attributes: [])
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
	public func loadCity(city cityName: String, province: String = "", country: String = "", complete: @escaping ([Dictionary<String, AnyObject>]) -> Void) {
		typealias JSON = Dictionary<String, AnyObject>
		queue.async {
			let baseSQL: WeatherSourceSQL = .cityFromName
			baseSQL.execute(information: cityName + ", " + province + ", " + country) { result in
				switch result {
				case .success(let citiesJSON):
					let unwrapped: [JSON]
					if let places = (citiesJSON["query"]?["results"] as? JSON)?["place"] as? [JSON] {
						unwrapped = places
					} else if let place = (citiesJSON["query"]?["results"] as? JSON)?["place"] as? JSON {
						unwrapped = [place]
					} else {
						DispatchQueue.main.async {
							complete([])
						}
						return
					}
					DispatchQueue.main.async {
						complete(unwrapped)
					}
				case .failure(_):
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
	public func loadCity(woeid: String, complete: @escaping (Dictionary<String, AnyObject>?) -> Void) {
		typealias JSON = Dictionary<String, AnyObject>
		queue.async {
			let baseSQL: WeatherSourceSQL = .cityFromWoeid
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .success(let json):
					guard let unwrapped = (json["query"]?["results"] as? JSON)?["place"] as? JSON else {
						DispatchQueue.main.async {
							complete(nil)
						}
						return
					}
					DispatchQueue.main.async {
						complete(unwrapped)
					}
				case .failure(_):
					complete(nil)
				}
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
	public func dayNight(woeid: String, complete: @escaping (_ sunrise: DateComponents?, _ sunset: DateComponents?) -> Void) {
		queue.async {
			let baseSQL: WeatherSourceSQL = .daytime
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .success(let daytimeJSON):
					guard
						let unwrapped = (daytimeJSON["query"]?["results"] as? Dictionary<String, AnyObject>)?["channel"]?["astronomy"] as? Dictionary<String, AnyObject>,
						let sunriseString = unwrapped["sunrise"] as? String,
						let sunrise = DateComponents(from: sunriseString),
						let sunsetString = unwrapped["sunset"] as? String,
						let sunset = DateComponents(from: sunsetString)
						else {
							DispatchQueue.main.async {
								complete(nil, nil)
							}
							return
					}
					DispatchQueue.main.async {
						complete(sunrise, sunset)
					}
				case .failure(_):
					complete(nil, nil)
				}
			}
		}
	}
	
	/**
	Parse a CLLocation to string information of city, province, country
	- Parameter location:
	Location needs to be parsed
	- Parameter complete:
	A delegate method used to call at the end of the function.
	Result can contain a generic type or an ErrorType
	*/
	public func locationParse(location: CLLocation, complete: @escaping (Dictionary<String, AnyObject>?) -> Void) {
		let geoCoder = CLGeocoder()
		queue.async {
			geoCoder.reverseGeocodeLocation(location) { (placeMarks, error) in
				if error != nil {
					DispatchQueue.main.async {
						complete(nil)
					}
				} else {
					guard
						let mark = placeMarks?.first,
						let state = mark.addressDictionary?["State"] as? String,
						let country = mark.addressDictionary?["Country"] as? String,
						let city = mark.addressDictionary?["City"] as? String
						else {
							DispatchQueue.main.async {
								complete(nil)
							}
							return
					}
					self.queue.sync {
						let loader = CityLoader()
						loader.loadCity(city: city, province: state, country: country) {
							guard let matchedCity = $0.first else { return }
							complete(matchedCity)
						}
					}
				}
			}
		}
	}
}
