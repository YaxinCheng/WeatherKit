//
//  WeatherKitTests.swift
//  WeatherKitTests
//
//  Created by Yaxin Cheng on 2016-09-09.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import XCTest
import CoreLocation
@testable import WeatherKit

class WeatherKitTests: XCTestCase {
	var weatherSource: WeatherStation!
	var halifaxLocation: CLLocation!
	var halifaxJSON: Dictionary<String, AnyObject>!
	var mockWeatherFahJSON: Dictionary<String, Double>!
	var mockWeatherCelJSON: Dictionary<String, Double>!
	var mockForecastFahJSON: Dictionary<String, Double>!
	var mockForecastCelJSON: Dictionary<String, Double>!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		weatherSource = WeatherStation()
		var halifaxJSON = Dictionary<String, AnyObject>()
		halifaxJSON["name"] = "Halifax" as AnyObject?
		halifaxJSON["admin1"] = "Nova Scotia" as AnyObject?
		halifaxJSON["country"] = "Canada" as AnyObject?
		halifaxJSON["woeid"] = "4177" as AnyObject?
		let centroid = ["latitude": "44.642078", "longitude": "-63.620571"]
		halifaxJSON["centroid"] = centroid as AnyObject?
		halifaxJSON["timezone"] = "America/Halifax" as AnyObject?
		self.halifaxJSON = halifaxJSON
		halifaxLocation = CLLocation(latitude: 44.642078, longitude: -63.620571)
		mockWeatherFahJSON = ["temperature": 73.0, "windChill": 77.0]
		mockForecastFahJSON = ["high": 77.0, "low": 73.0]
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testWrongCity() {
		let expectation = self.expectation(description: "loads")
		let cityLoader = CityLoader()
		cityLoader.loadCity(city: "Bkingalksdjflkasjdlfkjsakldjflkjsf") { (cities) in
			assert(cities.isEmpty)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testExistCity() {
		let expectation = self.expectation(description: "loads")
		let cityLoader = CityLoader()
		cityLoader.loadCity(city: "Halifax") { (cities) in
			assert(cities.count > 0)
			assert(cities[0]["name"] as? String == "Halifax")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testDiacriticCityName() {
		let expectation = self.expectation(description: "loadsCityWithDiacriticNames")
		let cityLoader = CityLoader()
		cityLoader.loadCity(city: "Montréal") { (cities) in
			assert(cities.count > 0)
			assert(cities[0]["name"] as? String == "Montreal")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testNonEnglishCityName() {
		let expectation = self.expectation(description: "loadsCityWithDiacriticNames")
		let cityLoader = CityLoader()
		cityLoader.loadCity(city: "成都") { (cities) in
			assert(cities.count > 0)
			assert(cities[0]["name"] as? String == "Chengdu")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testCityByWoeid() {
		let expectation = self.expectation(description: "loadCityWithWoeid")
		let cityLoader = CityLoader()
		cityLoader.loadCity(woeid: "4177") {
			guard let result = $0, let name = result["name"] as? String, let woeid = result["woeid"] as? String else {
				XCTFail()
				return
			}
			assert(name == "Halifax")
			assert(woeid == "4177")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testDaynight() {
		let expectation = self.expectation(description: "cityDaytime")
		let cityLoader = CityLoader()
		cityLoader.dayNight(woeid: "4177") {
			if $0 != nil && $1 != nil {
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
	
	func testParseLocation() {
		let expectation = self.expectation(description: "locationParse")
		let cityLoader = CityLoader()
		cityLoader.locationParse(location: halifaxLocation) {
			assert($0 != nil)
			assert($0!["name"] is String)
			assert($0!["name"] as! String == "Halifax")
			assert($0!["country"] is String)
			assert($0!["country"] as! String == "Canada")
			assert($0!["admin1"] is String)
			assert($0!["admin1"] as! String == "Nova Scotia")
			expectation.fulfill()
		}
		waitForExpectations(timeout: 10, handler: nil)
	}
	
	func testWeatherByName() {
		let expectation = self.expectation(description: "weatherByName")
		weatherSource.weather(city: "Halifax", province: "Nova Scotia", country: "Canada") { result in
			if case .success(let json) = result {
				assert(json["error"] == nil)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectations(timeout: 10, handler: nil)
	}
	
	func testWeatherByLocation() {
		let expectation = self.expectation(description: "weatherByLocation")
		weatherSource.weather(location: halifaxLocation) { (result) in
			if case .success(let json) = result {
				assert(json["error"] == nil)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectations(timeout: 10, handler: nil)
	}
	
	func testForecastByName() {
		let expectation = self.expectation(description: "forecastByName")
		weatherSource.forecast(city: "Halifax", province: "Nova Scotia", country: "Canada") { result in
			if case .success(let forecasts) = result {
				assert(forecasts.count == 10)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectations(timeout: 7, handler: nil)
	}
	
	func testForecastByLocation() {
		let expectation = self.expectation(description: "forecastsByLocation")
		weatherSource.forecast(location: halifaxLocation) { (result) in
			if case .success(let forecasts) = result {
				assert(forecasts.count == 10)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectations(timeout: 7, handler: nil)
	}
	
	func testTemperatureUnitConversion() {
		weatherSource.temperatureUnit = .fahrenheit
		let sameWeatherJSON = weatherSource.temperatureUnit.convert(mockWeatherFahJSON as Dictionary<String, AnyObject>)
		for (key, value) in sameWeatherJSON {
			assert(value is Double)
			assert((value as! Double) == mockWeatherFahJSON[key])
		}
		let sameForecastsJSON = weatherSource.temperatureUnit.convert(mockForecastFahJSON as Dictionary<String, AnyObject>)
		for (key, value) in sameForecastsJSON {
			assert(value is Double)
			assert((value as! Double) == mockForecastFahJSON[key])
		}
		weatherSource.temperatureUnit = .celsius
		let weatherCelJSON = weatherSource.temperatureUnit.convert(mockWeatherFahJSON as Dictionary<String, AnyObject>)
		guard let temperature = weatherCelJSON["temperature"] as? Double,
			let windChill = weatherCelJSON["windChill"] as? Double else {
				XCTFail()
				return
		}
		assert(abs(temperature - 22.7777777777778) <= 0.00001)
		assert(abs(windChill - 25) <= 0.0001)
		let forecastsCelJSON = weatherSource.temperatureUnit.convert(mockForecastFahJSON as Dictionary<String, AnyObject>)
		guard let low = forecastsCelJSON["low"] as? Double,
			let high = forecastsCelJSON["high"] as? Double else {
				XCTFail()
				return
		}
		assert(abs(low - 22.7777777777777777778) <= 0.00001)
		assert(abs(high - 25) <= 0.00001)
	}
	
	func testDistanceUnitConversion() {
		let mockWeatherMiJSON = ["visibility": 10.0]
		let sameJSON = weatherSource.distanceUnit.convert(mockWeatherMiJSON as Dictionary<String, AnyObject>)
		assert(sameJSON["visibility"] is Double)
		assert((sameJSON["visibility"] as! Double) == mockWeatherMiJSON["visibility"])
		weatherSource.distanceUnit = .km
		let kmJSON = weatherSource.distanceUnit.convert(mockWeatherMiJSON as Dictionary<String, AnyObject>)
		guard let visibilityInKM = kmJSON["visibility"] as? Double else { XCTFail(); return }
		assert(visibilityInKM - 16.1 <= 0.001)
	}
	
	func testDirectionUnitConversion() {
		weatherSource.directionUnit = .degree
		let mockDirectionJSON = ["windDirection": "371"]
		let sameJSON = weatherSource.directionUnit.convert(mockDirectionJSON as Dictionary<String, AnyObject>)
		assert(sameJSON["windDirection"] is String)
		assert(mockDirectionJSON["windDirection"] == sameJSON["windDirection"] as? String)
		weatherSource.directionUnit = .direction
		let directionJSON = weatherSource.directionUnit.convert(mockDirectionJSON as Dictionary<String, AnyObject>)
		assert(directionJSON["windDirection"] is String)
		assert(directionJSON["windDirection"] as? String != "DEGREE ERROR")
	}
	
	func testSpeedUnitConversion() {
		let originalSpeed: Double = 10
		let mockSpeedJSON = ["windSpeed": originalSpeed]
		let sameJSON = weatherSource.speedUnit.convert(mockSpeedJSON as Dictionary<String, AnyObject>)
		assert(sameJSON["windSpeed"] is Double)
		assert(sameJSON["windSpeed"] as? Double == mockSpeedJSON["windSpeed"])
		weatherSource.speedUnit = .kmph
		let speedJSON = weatherSource.speedUnit.convert(mockSpeedJSON as Dictionary<String, AnyObject>)
		assert(speedJSON["windSpeed"] is Double)
		assert((speedJSON["windSpeed"] as! Double) - 16.1 <= 0.01)
	}
    
}
