//
//  YahooWeatherSourceTests.swift
//  YahooWeatherSourceTests
//
//  Created by Yaxin Cheng on 2016-08-19.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import XCTest
import CoreLocation
@testable import YahooWeatherSource

class YahooWeatherSourceTests: XCTestCase {
	var weatherSource: YahooWeatherSource!
	var halifaxLocation: CLLocation!
	var halifaxJSON: Dictionary<String, AnyObject>!
	var failBlock: ((NSError?) -> Void)!
	var mockWeatherFahJSON: Dictionary<String, Double>!
	var mockWeatherCelJSON: Dictionary<String, Double>!
	var mockForecastFahJSON: Dictionary<String, Double>!
	var mockForecastCelJSON: Dictionary<String, Double>!
	var mockWeatherMiJSON: Dictionary<String, Double>!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		weatherSource = YahooWeatherSource()
		var halifaxJSON = Dictionary<String, AnyObject>()
		halifaxJSON["name"] = "Halifax"
		halifaxJSON["admin1"] = "Nova Scotia"
		halifaxJSON["country"] = "Canada"
		halifaxJSON["woeid"] = "4177"
		let centroid = ["latitude": "44.642078", "longitude": "-63.620571"]
		halifaxJSON["centroid"] = centroid
		halifaxJSON["timezone"] = "America/Halifax"
		self.halifaxJSON = halifaxJSON
		halifaxLocation = CLLocation(latitude: 44.642078, longitude: -63.620571)
		mockWeatherFahJSON = ["temperature": 73.0, "windChill": 77.0]
		mockForecastFahJSON = ["high": 77.0, "low": 73.0]
		mockWeatherMiJSON = ["visibility": 16.1]
		failBlock = {
			guard let error = $0 else { return }
			print(error.localizedDescription)
		}
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testWrongCity() {
		let expectation = expectationWithDescription("loads")
		let cityLoader = CityLoader()
		cityLoader.loadCity(city: "Bkingalksdjflkasjdlfkjsakldjflkjsf") { (cities) in
			assert(cities.isEmpty)
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testExistCity() {
		let expectation = expectationWithDescription("loads")
		let cityLoader = CityLoader()
		cityLoader.loadCity(city: "Halifax") { (cities) in
			assert(cities.count > 0)
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testCityByWoeid() {
		let expectation = expectationWithDescription("loadCityWithWoeid")
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
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testDaynight() {
		let expectation = expectationWithDescription("cityDaytime")
		let cityLoader = CityLoader()
		cityLoader.daytime(for: halifaxJSON) {
			guard
				let city = $0,
				let _ = city["sunrise"],
				let _ = city["sunset"]
			else {
				XCTFail()
				return
			}
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testParseLocation() {
		let expectation = expectationWithDescription("locationParse")
		weatherSource.locationParse(at: halifaxLocation) {
			assert($0 != nil)
			assert($0!["name"] is String)
			assert($0!["name"] as! String == "Halifax")
			assert($0!["country"] is String)
			assert($0!["country"] as! String == "Canada")
			assert($0!["admin1"] is String)
			assert($0!["admin1"] as! String == "Nova Scotia")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(10, handler: failBlock)
	}
	
	func testWeatherByName() {
		let expectation = expectationWithDescription("weatherByName")
		weatherSource.currentWeather(city: "Halifax", province: "Nova Scotia", country: "Canada") { result in
			if case .Success(let json) = result {
				assert(json["error"] == nil)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectationsWithTimeout(10, handler: failBlock)
	}
	
	func testWeatherByLocation() {
		let expectation = expectationWithDescription("weatherByLocation")
		weatherSource.currentWeather(at: halifaxLocation) { (result) in
			if case .Success(let json) = result {
				assert(json["error"] == nil)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectationsWithTimeout(10, handler: failBlock)
	}
	
	func testForecastByName() {
		let expectation = expectationWithDescription("forecastByName")
		weatherSource.fivedaysForecast(city: "Halifax", province: "Nova Scotia", country: "Canada") { result in
			if case .Success(let forecasts) = result {
				assert(forecasts.count == 10)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectationsWithTimeout(7, handler: failBlock)
	}
	
	func testForecastByLocation() {
		let expectation = expectationWithDescription("forecastsByLocation")
		weatherSource.fivedaysForecast(at: halifaxLocation) { (result) in
			if case .Success(let forecasts) = result {
				assert(forecasts.count == 10)
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectationsWithTimeout(7, handler: failBlock)
	}
	
	func testTemperatureUnitConvertion() {
		let sameWeatherJSON = weatherSource.temperatureUnit.convert(mockWeatherFahJSON)
		for (key, value) in sameWeatherJSON {
			assert(value is Double)
			assert((value as! Double) == mockWeatherFahJSON[key])
		}
		let sameForecastsJSON = weatherSource.temperatureUnit.convert(mockForecastFahJSON)
		for (key, value) in sameForecastsJSON {
			assert(value is Double)
			assert((value as! Double) == mockForecastFahJSON[key])
		}
		weatherSource.temperatureUnit = .Celsius
		let weatherCelJSON = weatherSource.temperatureUnit.convert(mockWeatherFahJSON)
		guard let temperature = weatherCelJSON["temperature"] as? Double,
			let windChill = weatherCelJSON["windChill"] as? Double else {
				XCTFail()
				return
		}
		assert(abs(temperature - 22.7777777777778) <= 0.00001)
		assert(abs(windChill - 25) <= 0.0001)
		let forecastsCelJSON = weatherSource.temperatureUnit.convert(mockForecastFahJSON)
		guard let low = forecastsCelJSON["low"] as? Double,
			let high = forecastsCelJSON["high"] as? Double else {
				XCTFail()
				return
		}
		assert(abs(low - 22.7777777777777777778) <= 0.00001)
		assert(abs(high - 25) <= 0.00001)
	}
	
	func testDistanceUnitConvertion() {
		let sameJSON = weatherSource.distanceUnit.convert(mockWeatherMiJSON)
		assert(sameJSON["visibility"] is Double)
		assert((sameJSON["visibility"] as! Double) == mockWeatherMiJSON["visibility"])
		weatherSource.distanceUnit = .Km
		let kmJSON = weatherSource.distanceUnit.convert(mockWeatherMiJSON)
		guard let visibilityInKM = kmJSON["visibility"] as? Double else { XCTFail(); return }
		assert(visibilityInKM - 0.0161 <= 0.0001)
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock {
			// Put the code you want to measure the time of here.
		}
	}
	
}
