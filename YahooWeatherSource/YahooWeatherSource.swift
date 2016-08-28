//
//  YahooWeatherSource.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

public struct YahooWeatherSource: WeatherSourceProtocol {
	private let queue: dispatch_queue_t
	private let cache: NSURLCache
	var temperatureUnit: TemperatureUnit = .Fahrenheit
	var distanceUnit: DistanceUnit = .Mi
	
	public init() {
		queue = dispatch_queue_create("WeatherSourceQueue", nil)
		cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 30 * 1024 * 1024, diskPath: "weather.urlcache")
		NSURLCache.setSharedURLCache(cache)
	}
	
	public func currentWeather(city city: String, province: String = "", country: String = "", complete: (Result<NSDictionary>) -> Void) {
		dispatch_async(queue) {
			let cityLoader = CityLoader()
			cityLoader.loadCity(city: city, province: province, country: country) {
				guard let woeid = $0.first?["woeid"] as? String else {
					let errorResult = Result<NSDictionary>.Failure(YahooWeatherError.FailedFindingCity)
					complete(errorResult)
					return
				}
				self.loadWeatherData(woeid: woeid, complete: complete)
			}
		}
	}
	
	public func currentWeather(at location: CLLocation, complete: (Result<NSDictionary>) -> Void) {
		locationParse(at: location) {
			guard let city = $0 else {
				let errorResult = Result<NSDictionary>.Failure(YahooWeatherError.FailedFindingCity)
				complete(errorResult)
				return
			}
			dispatch_async(self.queue) {
				self.loadWeatherData(woeid: city["woeid"] as! String, complete: complete)
			}
		}
	}
	
	public func locationParse(at location: CLLocation, complete: (NSDictionary?) -> Void) {
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
						let state = (mark.addressDictionary?["State"] as? String)?.formatted,
						let country = (mark.addressDictionary?["Country"] as? String)?.formatted,
						let city = (mark.addressDictionary?["City"] as? String)?.formatted
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
	
	public func fivedaysForecast(city city: String, province: String, country: String, complete: (Result<[NSDictionary]>) -> Void) {
		dispatch_async(queue) {
			let cityLoader = CityLoader()
			cityLoader.loadCity(city: city, province: province, country: country) {
				guard let woeid = $0.first?["woeid"] as? String else {
					let errorResult = Result<[NSDictionary]>.Failure(YahooWeatherError.FailedFindingCity)
					complete(errorResult)
					return
				}
				self.loadForecasts(woeid: woeid, complete: complete)
			}
		}
	}
	
	public func fivedaysForecast(at location: CLLocation, complete: (Result<[NSDictionary]> -> Void)) {
		locationParse(at: location) {
			guard let city = $0 else {
				let errorResult = Result<[NSDictionary]>.Failure(YahooWeatherError.FailedFindingCity)
				complete(errorResult)
				return
			}
			dispatch_async(self.queue) {
				self.loadForecasts(woeid: city["woeid"] as! String, complete: complete)
			}
		}
	}
	
	private func loadWeatherData(woeid woeid: String, complete: (Result<NSDictionary>) -> Void) {
		let baseSQL:WeatherSourceSQLPatterns = .weather
		let completeSQL = baseSQL.generateSQL(with: woeid)
		
		dispatch_async(queue) {
			self.sendRequst(completeSQL) {
				guard let weatherJSON = $0 as? NSDictionary,
					let unwrapped = (weatherJSON["query"] as? NSDictionary)?["results"]?["channel"] as? Dictionary<String, AnyObject>
					else {
						let error = Result<NSDictionary>.Failure(YahooWeatherError.LoadFailed)
						dispatch_async(dispatch_get_main_queue()) {
							complete(error)
						}
						return
				}
				let formattedJSON = self.formatWeatherJSON(unwrapped)
				let temperatureUnitConvertedJSON = self.temperatureUnit.convert(formattedJSON)
				let distanceUnitConvertedJSON = self.distanceUnit.convert(temperatureUnitConvertedJSON)
				let result = Result<NSDictionary>.Success(distanceUnitConvertedJSON)
				dispatch_async(dispatch_get_main_queue()) {
					complete(result)
				}
			}
		}
	}
	
	private func loadForecasts(woeid woeid: String, complete: (Result<[NSDictionary]>) -> Void) {
		let baseSQL:WeatherSourceSQLPatterns = .forecast
		let completeSQL = baseSQL.generateSQL(with: woeid)
		dispatch_async(queue) {
			self.sendRequst(completeSQL) {
				guard let weatherJSON = $0 as? NSDictionary,
					let unwrapped = (((weatherJSON["query"] as? NSDictionary)?["results"] as? NSDictionary)?["channel"]) as? [Dictionary<String, AnyObject>]
					else {
						let error = Result<[NSDictionary]>.Failure(YahooWeatherError.LoadFailed)
						dispatch_async(dispatch_get_main_queue()) {
							complete(error)
						}
						return
				}
				let forecasts = unwrapped
					.flatMap { $0["item"]?["forecast"] as? Dictionary<String, AnyObject> }
					.map { self.temperatureUnit.convert($0) }
					.map { self.distanceUnit.convert($0) }
				
				let result = Result<[NSDictionary]>.Success(forecasts)
				dispatch_async(dispatch_get_main_queue()) {
					complete(result)
				}
			}
		}
	}
	
	private func formatWeatherJSON(json: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		var newJSON = Dictionary<String, AnyObject>()
		newJSON["temperature"] = ((json["item"]?["condition"] as? NSDictionary)?["temp"] as? NSString)?.doubleValue
		newJSON["condition"] = (json["item"]?["condition"] as? NSDictionary)?["text"]
		newJSON["windChill"] = (json["wind"]?["chill"] as? NSString)?.doubleValue
		newJSON["windSpeed"] = json["wind"]?["speed"]
		newJSON["windDirection"] = json["wind"]?["direction"]
		newJSON["humidity"] = json["atmosphere"]?["humidity"]
		newJSON["visibility"] = json["atmosphere"]?["visibility"]
		newJSON["pressure"] = json["atmosphere"]?["pressure"]
		newJSON["sunrise"] = NSDateComponents(from: (json["astronomy"]?["sunrise"] as? String) ?? "")
		newJSON["sunset"] = NSDateComponents(from: (json["astronomy"]?["sunset"] as? String) ?? "")
		
		return newJSON
	}
}

public enum YahooWeatherError: ErrorType {
	case LoadFailed
	case FailedFindingCity
}