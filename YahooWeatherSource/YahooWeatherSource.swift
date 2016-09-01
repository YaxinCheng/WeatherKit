//
//  YahooWeatherSource.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

public struct YahooWeatherSource {
	private let queue: dispatch_queue_t
	private let cache: NSURLCache
	var temperatureUnit: TemperatureUnit
	var distanceUnit: DistanceUnit
	var directionUnit: DirectionUnit
	var speedUnit: SpeedUnit
	
	public init(temperatureUnit tunit: TemperatureUnit = .celsius, distanceUnit: DistanceUnit = .mi, directionUnit: DirectionUnit = .direction, speedUnit: SpeedUnit = .mph) {
		temperatureUnit = tunit
		self.distanceUnit = distanceUnit
		self.directionUnit = directionUnit
		self.speedUnit = speedUnit
		queue = dispatch_queue_create("WeatherSourceQueue", nil)
		cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 30 * 1024 * 1024, diskPath: "weather.urlcache")
		NSURLCache.setSharedURLCache(cache)
	}
	
	public func currentWeather(city city: String, province: String = "", country: String = "", complete: (Result<Dictionary<String, AnyObject>>) -> Void) {
		dispatch_async(queue) {
			let cityLoader = CityLoader()
			cityLoader.loadCity(city: city, province: province, country: country) {
				guard let woeid = $0.first?["woeid"] as? String else {
					let errorResult = Result<Dictionary<String, AnyObject>>(error: YahooWeatherError.FailedFindingCity)
					complete(errorResult)
					return
				}
				self.loadWeatherData(woeid: woeid, complete: complete)
			}
		}
	}
	
	public func currentWeather(at location: CLLocation, complete: (Result<Dictionary<String, AnyObject>>) -> Void) {
		locationParse(at: location) {
			guard let city = $0 else {
				let errorResult = Result<Dictionary<String, AnyObject>>(error: YahooWeatherError.FailedFindingCity)
				complete(errorResult)
				return
			}
			dispatch_async(self.queue) {
				self.loadWeatherData(woeid: city["woeid"] as! String, complete: complete)
			}
		}
	}
	
	public func locationParse(at location: CLLocation, complete: (Dictionary<String, AnyObject>?) -> Void) {
		let geoCoder = CLGeocoder()
		dispatch_async(queue) {
			geoCoder.reverseGeocodeLocation(location) { (placeMarks, error) in
				if error != nil {
					dispatch_async(dispatch_get_main_queue()) {
						complete(nil)
					}
				} else {
					guard
						let mark = placeMarks?.first,
						let state = mark.addressDictionary?["State"] as? String,
						let country = mark.addressDictionary?["Country"] as? String,
						let city = mark.addressDictionary?["City"] as? String
					else {
							dispatch_async(dispatch_get_main_queue()) {
								complete(nil)
							}
							return
					}
					dispatch_sync(self.queue) {
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
	
	public func fivedaysForecast(city city: String, province: String, country: String, complete: (Result<[Dictionary<String, AnyObject>]>) -> Void) {
		dispatch_async(queue) {
			let cityLoader = CityLoader()
			cityLoader.loadCity(city: city, province: province, country: country) {
				guard let woeid = $0.first?["woeid"] as? String else {
					let errorResult = Result<[Dictionary<String, AnyObject>]>(error: YahooWeatherError.FailedFindingCity)
					complete(errorResult)
					return
				}
				self.loadForecasts(woeid: woeid, complete: complete)
			}
		}
	}
	
	public func fivedaysForecast(at location: CLLocation, complete: (Result<[Dictionary<String, AnyObject>]> -> Void)) {
		locationParse(at: location) {
			guard let city = $0 else {
				let errorResult = Result<[Dictionary<String, AnyObject>]>(error: YahooWeatherError.FailedFindingCity)
				complete(errorResult)
				return
			}
			dispatch_async(self.queue) {
				self.loadForecasts(woeid: city["woeid"] as! String, complete: complete)
			}
		}
	}
	
	private func loadWeatherData(woeid woeid: String, complete: (Result<Dictionary<String, AnyObject>>) -> Void) {
		let baseSQL:WeatherSourceSQL = .weather
		typealias JSON = Dictionary<String, AnyObject>
		dispatch_async(queue) {
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .Success(let weatherJSON):
					guard let unwrapped = (weatherJSON["query"]?["results"] as? JSON)?["channel"] as? JSON else {
						let error = Result<JSON>(error: YahooWeatherError.LoadFailed)
						dispatch_async(dispatch_get_main_queue()) {
							complete(error)
						}
						return
					}
					let formattedJSON: JSON = {
						let format = self.formatWeatherJSON(unwrapped)
						let temperatureUnitConvertedJSON = self.temperatureUnit.convert(format)
						let distanceUnitConvertedJSON = self.distanceUnit.convert(temperatureUnitConvertedJSON)
						let directionUnitConvertedJSON = self.directionUnit.convert(distanceUnitConvertedJSON)
						let speedUnitConvertedJSON = self.speedUnit.convert(directionUnitConvertedJSON)
						return speedUnitConvertedJSON
					}()
					let result = Result<JSON>(value: formattedJSON)
					dispatch_async(dispatch_get_main_queue()) {
						complete(result)
					}
				case .Failure(_):
					complete(result)
				}
			}
		}
	}
	
	private func loadForecasts(woeid woeid: String, complete: (Result<[Dictionary<String, AnyObject>]>) -> Void) {
		let baseSQL:WeatherSourceSQL = .forecast
		typealias JSON = Dictionary<String, AnyObject>
		dispatch_async(queue) {
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .Success(let yahooJSON):
					guard let unwrapped = (yahooJSON["query"]?["results"] as? JSON)?["channel"] as? [JSON] else {
						let error = Result<[JSON]>(error: YahooWeatherError.LoadFailed)
						dispatch_async(dispatch_get_main_queue()) {
							complete(error)
						}
						return
					}
					print(unwrapped.count)
					print(unwrapped)
					let forecasts = unwrapped
						.flatMap { $0["item"]?["forecast"] as? Dictionary<String, AnyObject> }
						.map { self.temperatureUnit.convert($0) }
						.map { self.distanceUnit.convert($0) }
					let result = Result<[JSON]>(value: forecasts)
					dispatch_async(dispatch_get_main_queue()) {
						complete(result)
					}
				case .Failure(let error):
					let errorResult = Result<[JSON]>(error: error)
					complete(errorResult)
				}
			}
		}
	}
	
	private func formatWeatherJSON(json: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		var newJSON = Dictionary<String, AnyObject>()
		newJSON["temperature"] = ((json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["temp"] as? NSString)?.doubleValue
		newJSON["condition"] = (json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["text"]
		newJSON["windChill"] = (json["wind"]?["chill"] as? NSString)?.doubleValue
		newJSON["windSpeed"] = (json["wind"]?["speed"] as? NSString)?.doubleValue
		newJSON["windDirection"] = json["wind"]?["direction"]
		newJSON["humidity"] = json["atmosphere"]?["humidity"]
		newJSON["visibility"] = json["atmosphere"]?["visibility"]
		newJSON["pressure"] = json["atmosphere"]?["pressure"]
		newJSON["trend"] = (json["atmosphere"]?["rising"] as? Int) == 0 ? "Falling" : "Rising"
		newJSON["sunrise"] = NSDateComponents(from: (json["astronomy"]?["sunrise"] as? String) ?? "")
		newJSON["sunset"] = NSDateComponents(from: (json["astronomy"]?["sunset"] as? String) ?? "")
		
		return newJSON
	}
	
	public func clearCache() {
		cache.removeAllCachedResponses()
	}
}

public enum YahooWeatherError: ErrorType {
	case LoadFailed
	case FailedFindingCity
}