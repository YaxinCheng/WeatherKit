//
//  CityLoader.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct CityLoader: WeatherSourceProtocol {

	let queue: dispatch_queue_t
	public init() {
		queue = dispatch_queue_create("CityLoaderQueue", nil)
	}
	
	public func loadCity(cityName: String, complete: ([NSDictionary]) -> Void) {
		dispatch_async(queue) {
			let baseSQL: WeatherSourceSQLPatterns = .city
			let sql = baseSQL.generateSQL(with: cityName)
			self.sendRequst(sql) {
				guard let citiesJSON = $0 as? NSDictionary else {
					dispatch_async(dispatch_get_main_queue()) {
						complete([])
					}
					return
				}
				let unwrapped: [NSDictionary]
				if let places = (citiesJSON["query"] as? NSDictionary)?["results"]?["place"] as? [NSDictionary] {
					unwrapped = places
				} else if let place = (citiesJSON["query"] as? NSDictionary)?["results"]?["place"] as? NSDictionary {
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
			}
		}
	}
	
	
	public func daytime(for city: NSDictionary, complete: (NSDictionary?) -> Void) {
		dispatch_sync(queue) {
			guard let woeid = city["woeid"] as? String else { return }
			self.updateTime(woeid: woeid) {
				guard $0 != nil && $1 != nil else {
					dispatch_async(dispatch_get_main_queue()) {
						complete(nil)
					}
					return
				}
				var cityDictionary: Dictionary<String, AnyObject> = city as! Dictionary<String, AnyObject>
				cityDictionary["sunrise"] = $0
				cityDictionary["sunset"] = $1
				complete(cityDictionary)
			}
		}
	}
	
	public func updateTime(woeid woeid: String, complete: (sunrise: NSDateComponents?, sunset: NSDateComponents?) -> Void ) {
		dispatch_async(queue) {
			let baseSQL = WeatherSourceSQLPatterns.daytime
			let sql = baseSQL.generateSQL(with: woeid)
			dispatch_sync(self.queue) {
				self.sendRequst(sql) {
					guard
						let daytimeJSON = $0 as? NSDictionary,
						let unwrapped = ((daytimeJSON["query"] as? NSDictionary)?["results"]?["channel"] as? NSDictionary)?["astronomy"] as? NSDictionary,
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
				}
			}
		}
	}
}