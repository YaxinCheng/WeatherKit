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
	private let queue: DispatchQueue// Async queue
	private let cache: URLCache// URL Cache
	/**
	Temeperature unit for weather and forecasts
	
	Options: Fahrenheit or Celsius
	*/
	public var temperatureUnit: TemperatureUnit
	
	/**
	Distance unit for weather
	
	Options: Meters or Kilometers
	*/
	public var distanceUnit: DistanceUnit

	/**
	Direction unit for weather
	
	Options: Degrees or Compass Direction
	*/
	public var directionUnit: DirectionUnit
	
	/**
	Speed unit for weather
	
	Options: Meters/hour or Kilometers/hour
	*/
	public var speedUnit: SpeedUnit
	
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
	public init(temperatureUnit: TemperatureUnit = .celsius, distanceUnit: DistanceUnit = .mi, directionUnit: DirectionUnit = .direction, speedUnit: SpeedUnit = .mph) {
		self.temperatureUnit = temperatureUnit
		self.distanceUnit = distanceUnit
		self.directionUnit = directionUnit
		self.speedUnit = speedUnit
		queue = DispatchQueue(label: "WeatherSourceQueue", attributes: [])
		cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 30 * 1024 * 1024, diskPath: "weather.urlcache")
		URLCache.shared = cache
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
	public func weather(city: String, province: String = "", country: String = "", complete: @escaping (Result<Dictionary<String, AnyObject>>) -> Void) {
		queue.async {
			let cityLoader = CityLoader()
			cityLoader.loadCity(city: city, province: province, country: country) {
				guard let woeid = $0.first?["woeid"] as? String else {
					let errorResult = Result<Dictionary<String, AnyObject>>(error: YahooWeatherError.failedFindingCity)
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
	public func weather(location: CLLocation, complete: @escaping (Result<Dictionary<String, AnyObject>>) -> Void) {
		let cityLoader = CityLoader()
		cityLoader.locationParse(location: location) {
			guard let city = $0 else {
				let errorResult = Result<Dictionary<String, AnyObject>>(error: YahooWeatherError.failedFindingCity)
				complete(errorResult)
				return
			}
			self.queue.async {
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
	public func forecast(city: String, province: String, country: String, complete: @escaping (Result<[Dictionary<String, AnyObject>]>) -> Void) {
		queue.async {
			let cityLoader = CityLoader()
			cityLoader.loadCity(city: city, province: province, country: country) {
				guard let woeid = $0.first?["woeid"] as? String else {
					let errorResult = Result<[Dictionary<String, AnyObject>]>(error: YahooWeatherError.failedFindingCity)
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
	public func forecast(location: CLLocation, complete: @escaping ((Result<[Dictionary<String, AnyObject>]>) -> Void)) {
		let cityLoader = CityLoader()
		cityLoader.locationParse(location: location) {
			guard let city = $0 else {
				let errorResult = Result<[Dictionary<String, AnyObject>]>(error: YahooWeatherError.failedFindingCity)
				complete(errorResult)
				return
			}
			self.queue.async {
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
	private func loadWeatherData(woeid: String, complete: @escaping (Result<Dictionary<String, AnyObject>>) -> Void) {
		let baseSQL:WeatherSourceSQL = .weather
		typealias JSON = Dictionary<String, AnyObject>
		queue.async {
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .success(let weatherJSON):
					guard let unwrapped = (weatherJSON["query"]?["results"] as? JSON)?["channel"] as? JSON else {
						let error = Result<JSON>(error: YahooWeatherError.loadFailed)
						DispatchQueue.main.async {
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
					DispatchQueue.main.async {
						complete(result)
					}
				case .failure(_):
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
	private func loadForecasts(woeid: String, complete: @escaping (Result<[Dictionary<String, AnyObject>]>) -> Void) {
		let baseSQL:WeatherSourceSQL = .forecast
		typealias JSON = Dictionary<String, AnyObject>
		queue.async {
			baseSQL.execute(information: woeid) { (result) in
				switch result {
				case .success(let yahooJSON):
					guard let unwrapped = (yahooJSON["query"]?["results"] as? JSON)?["channel"] as? [JSON] else {
						let error = Result<[JSON]>(error: YahooWeatherError.loadFailed)
						DispatchQueue.main.async {
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
					DispatchQueue.main.async {
						complete(result)
					}
				case .failure(let error):
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
	private func formatWeatherJSON(_ json: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		var newJSON = Dictionary<String, AnyObject>()
		newJSON["temperature"] = ((json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["temp"] as? NSString)?.doubleValue as AnyObject?
		newJSON["condition"] = (json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["text"]
		newJSON["conditionCode"] = ((json["item"]?["condition"] as? Dictionary<String, AnyObject>)?["code"] as? NSString)?.integerValue as AnyObject?
		newJSON["windChill"] = (json["wind"]?["chill"] as? NSString)?.doubleValue as AnyObject?
		newJSON["windSpeed"] = (json["wind"]?["speed"] as? NSString)?.doubleValue as AnyObject?
		newJSON["windDirection"] = json["wind"]?["direction"] as AnyObject?
		newJSON["humidity"] = json["atmosphere"]?["humidity"] as AnyObject?
		newJSON["visibility"] = (json["atmosphere"]?["visibility"] as? NSString)?.doubleValue as AnyObject?
		newJSON["pressure"] = json["atmosphere"]?["pressure"] as AnyObject?
		let trend = (json["atmosphere"]?["rising"] as? Int) == 0 ? "Falling" : "Rising"
		newJSON["trend"] = trend as AnyObject
		newJSON["sunrise"] = DateComponents(from: (json["astronomy"]?["sunrise"] as? String) ?? "") as AnyObject
		newJSON["sunset"] = DateComponents(from: (json["astronomy"]?["sunset"] as? String) ?? "") as AnyObject
		
		return newJSON
	}
	
	/**
	Convert the string values of json to double values
	
	- Parameter json:
	Original json needs to be re-structured
	- returns:
	A newly packed json
	*/
	private func formatForecastJSON(_ json: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		var newJSON = json
		newJSON["high"] = (json["high"] as? NSString)?.doubleValue as AnyObject?
		newJSON["low"] = (json["low"] as? NSString)?.doubleValue as AnyObject?
		return newJSON
	}
	
	/**
	Clear stored request cache
	*/
	public func clearCache() {
		cache.removeAllCachedResponses()
	}
}

public enum YahooWeatherError: Error {
	case loadFailed
	case failedFindingCity
}
