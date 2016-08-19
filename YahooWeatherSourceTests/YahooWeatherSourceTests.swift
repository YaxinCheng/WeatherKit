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
	var halifaxCity: City!
	var halifaxLocation: CLLocation!
	var failBlock: ((NSError?) -> Void)!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		weatherSource = YahooWeatherSource()
		var halifaxJSON = Dictionary<String, AnyObject>()
		halifaxJSON["name"] = "Halifax"
		halifaxJSON["admin1"] = "Nova Scotia"
		halifaxJSON["country"] = "Canada"
		halifaxJSON["woeid"] = "4177"
		let centroid = Dictionary<String, String>(dictionaryLiteral: ("latitude", "44.642078"), ("longitude", "-63.620571"))
		halifaxJSON["centroid"] = centroid
		halifaxJSON["timezone"] = "America/Halifax"
		halifaxCity = City(from: halifaxJSON)!
		halifaxLocation = CLLocation(latitude: 44.642078, longitude: -63.620571)
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
		let cityLoader = CityLoader(input: "Bkingalksdjflkasjdlfkjsakldjflkjsf")
		cityLoader.loads { (cities) in
			assert(cities.isEmpty)
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testExistCity() {
		let expectation = expectationWithDescription("loads")
		let cityLoader = CityLoader(input: "Halifax")
		cityLoader.loads { (cities) in
			assert(cities.count > 0)
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testWeatherInCity() {
		let expectation = expectationWithDescription("weatherInCity")
		weatherSource.currentWeather(at: halifaxCity) { (result) in
			if case .Success(_) = result {
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testParseLocation() {
		let expectation = expectationWithDescription("locationParse")
		weatherSource.locationParse(at: halifaxLocation) {
			assert($0 != nil)
			assert($0!.name == "Halifax")
			assert($0!.country == "Canada")
			assert($0!.province == "Nova Scotia")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testWeatherByLocation() {
		let expectation = expectationWithDescription("weatherByLocation")
		weatherSource.currentWeather(at: halifaxLocation) { (result) in
			if case .Success(_) = result {
				expectation.fulfill()
			} else {
				XCTFail()
			}
		}
		waitForExpectationsWithTimeout(5, handler: failBlock)
	}
	
	func testForecastInCity() {
		let expectation = expectationWithDescription("forecastsInCity")
		weatherSource.fivedaysForecast(at: halifaxCity) { (result) in
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
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock {
			// Put the code you want to measure the time of here.
		}
	}
	
}
