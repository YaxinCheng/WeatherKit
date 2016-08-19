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
	
	init() {
		queue = dispatch_queue_create("WeatherSourceQueue", nil)
		cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 30 * 1024 * 1024, diskPath: "weather.urlcache")
		NSURLCache.setSharedURLCache(cache)
	}
	
	public func currentWeather(at city: City, complete: (Result<Weather>) -> Void) {
		let woeid = city.woeid
		dispatch_async(queue) {
			self.loadWeatherData(at: woeid, complete: complete)
		}
	}
	
	public func currentWeather(at location: CLLocation, complete: (Result<Weather>) -> Void) {
		locationParse(at: location) {
			guard let city = $0 else {
				let errorResult = Result<Weather>.Failure(YahooWeatherError.FailedFindingCity)
				complete(errorResult)
				return
			}
			dispatch_async(self.queue) {
				self.loadWeatherData(at: city.woeid, complete: complete)
			}
		}
	}
	
	public func locationParse(at location: CLLocation, complete: (City?) -> Void) {
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
						let loader = CityLoader(input: "\(city), \(state), \(country)")
						loader.loads {
							guard let matchedCity = $0.first else { return }
							complete(matchedCity)
						}
					}
				}
			}
		}
	}
	
	public func fivedaysForecast(at city: City, complete: (Result<[Forecast]> -> Void)) {
		dispatch_async(queue) {
			self.loadForecasts(at: city.woeid, complete: complete)
		}
	}
	
	public func fivedaysForecast(at location: CLLocation, complete: (Result<[Forecast]> -> Void)) {
		locationParse(at: location) {
			guard let city = $0 else {
				let errorResult = Result<[Forecast]>.Failure(YahooWeatherError.FailedFindingCity)
				complete(errorResult)
				return
			}
			dispatch_async(self.queue) {
				self.loadForecasts(at: city.woeid, complete: complete)
			}
		}
	}
	
	private func loadWeatherData(at locationString: String, complete: (Result<Weather>) -> Void) {
		let baseSQL:WeatherSourceSQLPatterns = .weather
		let completeSQL = baseSQL.generateSQL(with: locationString)
		
		dispatch_async(queue) {
			self.sendRequst(completeSQL) {
				guard let weatherJSON = $0 as? NSDictionary,
					let unwrapped = (weatherJSON["query"] as? NSDictionary)?["results"]?["channel"] as? Dictionary<String, AnyObject>
					else {
						let error = Result<Weather>.Failure(YahooWeatherError.LoadFailed)
						dispatch_async(dispatch_get_main_queue()) {
							complete(error)
						}
						return
				}
				let formattedJSON = self.formatWeatherJSON(unwrapped)
				guard let weather = Weather(with: formattedJSON) else { return }
				let result = Result<Weather>.Success(WeatherUnit.convert(weather, from: .Fahrenheit, to: .Celsius))
				dispatch_async(dispatch_get_main_queue()) {
					complete(result)
				}
			}
		}
	}
	
	private func loadForecasts(at locationString: String, complete: (Result<[Forecast]>) -> Void) {
		let baseSQL:WeatherSourceSQLPatterns = .forecast
		let completeSQL = baseSQL.generateSQL(with: locationString)
		dispatch_async(queue) {
			self.sendRequst(completeSQL) {
				guard let weatherJSON = $0 as? NSDictionary,
					let unwrapped = (((weatherJSON["query"] as? NSDictionary)?["results"] as? NSDictionary)?["channel"]) as? [Dictionary<String, AnyObject>]
					else {
						let error = Result<[Forecast]>.Failure(YahooWeatherError.LoadFailed)
						dispatch_async(dispatch_get_main_queue()) {
							complete(error)
						}
						return
				}
				let forecasts = unwrapped.flatMap { $0["item"]?["forecast"] as? NSDictionary }.flatMap { Forecast(with: $0) }
				let result = Result<[Forecast]>.Success(forecasts)
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
		newJSON["windChill"] = json["wind"]?["chill"]
		newJSON["windSpeed"] = json["wind"]?["speed"]
		newJSON["windDirection"] = json["wind"]?["direction"]
		newJSON["humidity"] = json["atmosphere"]?["humidity"]
		newJSON["visibility"] = json["atmosphere"]?["visibility"]
		newJSON["pressure"] = json["atmosphere"]?["pressure"]
		newJSON["sunrise"] = processTime(json["astronomy"]?["sunrise"] as? String)
		newJSON["sunset"] = processTime(json["astronomy"]?["sunset"] as? String)
		
		return newJSON
	}
	
	private func processTime(time: String?) -> NSDateComponents? {
		guard let timeComponents = time?.characters.split(isSeparator: {$0 == " " || $0 == ":"}).map(String.init) where timeComponents.count >= 2 else { return nil }
		let elements = timeComponents.flatMap { Int($0) }
		let component = NSDateComponents()
		component.hour = elements[0] + (timeComponents[2] == "am" ? 0 : 12)
		component.minute = elements[1]
		return component
	}
}

public enum YahooWeatherError: ErrorType {
	case LoadFailed
	case FailedFindingCity
}