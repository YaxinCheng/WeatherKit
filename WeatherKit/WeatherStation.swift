//
//  WeatherStation.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

public struct WeatherStation {
	private let queue: dispatch_queue_t// Async queue
	private let cache: NSURLCache// URL Cache
	/**
	Temeperature unit for weather and forecasts
	
	Options: Fahrenheit or Celsius
	*/
	var temperatureUnit: TemperatureUnit
	
	/**
	Distance unit for weather
	
	Options: Meters or Kilometers
	*/
	var distanceUnit: DistanceUnit

	/**
	Direction unit for weather
	
	Options: Degrees or Compass Direction
	*/
	var directionUnit: DirectionUnit
	
	/**
	Speed unit for weather
	
	Options: Meters/hour or Kilometers/hour
	*/
	var speedUnit: SpeedUnit
	
	/**
	Constructs a new weather source object with related units
	
	- Parameter temperatureUnit:
		Temeperature unit for weather and forecasts
	
		Options: Fahrenheit or Celsius
	
		Celsius by default
	- Parameter distanceUnit:
		Distance unit for weather
		
		Options: Meters or Kilometers
		
		Meters by default
	- Parameter directionUnit:
		Direction unit for weather
		
		Options: Degrees or Compass Direction
		
		Compass Direction by default
	- Parameter speedUnit:
		Speed unit for weather
		
		Options: Meters/hour or Kilometers/hour
		
		Meters/hour by default
	*/
	public init(temperatureUnit tunit: TemperatureUnit = .celsius, distanceUnit: DistanceUnit = .mi, directionUnit: DirectionUnit = .direction, speedUnit: SpeedUnit = .mph) {
		self.temperatureUnit = tunit
		self.distanceUnit = distanceUnit
		self.directionUnit = directionUnit
		self.speedUnit = speedUnit
		queue = dispatch_queue_create("WeatherSourceQueue", nil)
		cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 30 * 1024 * 1024, diskPath: "weather.urlcache")
		NSURLCache.setSharedURLCache(cache)
	}
	
	/**
	Search and load current weather information by city information like names. At the end of the function, the function bypasses calls to a delegate method
	
	- Parameter city:
		Name of the city using for searching
	- Parameter province:
		Name of the province where the city is, using for narrowing down the searching scope
	- Parameter country:
		Name of the country where the province is, using for narrowing down the searching scope
	- Parameter complete:
		A delegate method used to call at the end of the function.
		Result can contain a generic type or an ErrorType
	*/
	public func weather(city city: String, province: String = "", country: String = "", complete: (Result<Dictionary<String, AnyObject>>) -> Void) {
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
	
	/**
	Search and load current weather information by CLLocation. At the end of the function, the function bypasses calls to a delegate method
	
	- Parameter location: 
		Location used for searching and loading weather information
	- Parameter complete:
		A delegate method used to call at the end of the function.
		Result can contain a generic type or an ErrorType
	*/
	public func weather(location location: CLLocation, complete: (Result<Dictionary<String, AnyObject>>) -> Void) {
		let cityLoader = CityLoader()
		cityLoader.locationParse(location: location) {
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
	
	/**
	Search and load five days weather forecasts by city information like names. At the end of the function, the function bypasses calls to a delegate method
	- Parameter city:
		Name of the city using for searching
	- Parameter province:
		Name of the province where the city is, using for narrowing down the searching scope
	- Parameter country:
		Name of the country where the province is, using for narrowing down the searching scope
	- Parameter complete:
		A delegate method used to call at the end of the function.
		Result can contain a generic type or an ErrorType
	*/
	public func forecast(city city: String, province: String, country: String, complete: (Result<[Dictionary<String, AnyObject>]>) -> Void) {
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
	
	/**
	Search and load five days weather forecasts by CLLocation. At the end of the function, the function bypasses calls to a delegate method
	
	- Parameter location:
		Location used for searching and loading weather information
	- Parameter complete:
		A delegate method used to call at the end of the function.
		Result can contain a generic type or an ErrorType
	*/
	public func forecast(location location: CLLocation, complete: (Result<[Dictionary<String, AnyObject>]> -> Void)) {
		let cityLoader = CityLoader()
		cityLoader.locationParse(location: location) {
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
	
	/**
	Load weather information by woeid. At the end of the function, the function bypasses calls to a delegate method
	
	- Parameter woeid:
		WOEID is a unique value used to locate a city
	- Parameter complete:
		A delegate method used to call at the end of the function.
		Result can contain a generic type or an ErrorType
	*/
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
	
	/**
	Load forecasts information by woeid. At the end of the function, the function bypasses calls to a delegate method
	
	- Parameter woeid:
	WOEID is a unique value used to locate a city
	- Parameter complete:
	A delegate method used to call at the end of the function.
	Result can contain a generic type or an ErrorType
	*/
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
					let forecasts = unwrapped
						.flatMap { $0["item"]?["forecast"] as? Dictionary<String, AnyObject> }
						.map { self.formatForecastJSON($0) }
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
	
	/**
	Unwrap the original JSON from Yahoo, and pack them again to simpler architectures
	
	- Parameter json:
		Original json needs to be re-structured
	- returns:
		A newly packed json
	*/
	private func formatWeatherJSON(json: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		var newJSON = Dictionary<String, AnyObject>()
		newJSON["temperature"] = ((json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["temp"] as? NSString)?.doubleValue
		newJSON["condition"] = (json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["text"]
		newJSON["conditionCode"] = ((json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["code"] as? NSString)?.integerValue
		newJSON["windChill"] = (json["wind"]?["chill"] as? NSString)?.doubleValue
		newJSON["windSpeed"] = (json["wind"]?["speed"] as? NSString)?.doubleValue
		newJSON["windDirection"] = json["wind"]?["direction"]
		newJSON["humidity"] = json["atmosphere"]?["humidity"]
		newJSON["visibility"] = (json["atmosphere"]?["visibility"] as? NSString)?.doubleValue
		newJSON["pressure"] = json["atmosphere"]?["pressure"]
		newJSON["trend"] = (json["atmosphere"]?["rising"] as? Int) == 0 ? "Falling" : "Rising"
		newJSON["sunrise"] = NSDateComponents(from: (json["astronomy"]?["sunrise"] as? String) ?? "")
		newJSON["sunset"] = NSDateComponents(from: (json["astronomy"]?["sunset"] as? String) ?? "")
		
		return newJSON
	}
	
	/**
	Convert the string values of json to double values
	
	- Parameter json:
	Original json needs to be re-structured
	- returns:
	A newly packed json
	*/
	private func formatForecastJSON(json: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		var newJSON = json
		newJSON["high"] = (json["high"] as? NSString)?.doubleValue
		newJSON["low"] = (json["low"] as? NSString)?.doubleValue
		return newJSON
	}
	
	/**
	Clear stored request cache
	*/
	public func clearCache() {
		cache.removeAllCachedResponses()
	}
}

public enum YahooWeatherError: ErrorType {
	case LoadFailed
	case FailedFindingCity
}