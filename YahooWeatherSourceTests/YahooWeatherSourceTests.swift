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
	var failBlock: ((NSError?) -> Void)!
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		weatherSource = YahooWeatherSource()
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
		waitForExpectationsWithTimeout(7, handler: failBlock)
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
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock {
			// Put the code you want to measure the time of here.
		}
	}
	
}
