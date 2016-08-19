//
//  Weather.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-07-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct Weather {
	public let condition: WeatherCondition
	public var temprature: Int
	public let pressure: String
	public var windTemperatue: Int
	public let sunriseTime: NSDateComponents
	public let sunsetTime: NSDateComponents
	public let visibility: String
	public let windsDirection: String
	public let humidity: String
	public let windsSpeed: String
	
	public init?(with JSON: NSDictionary) {
		guard
			let temprature = JSON["temperature"] as? Double,
			let pressure = JSON["pressure"] as? String,
			let windTemperatue = (JSON["windChill"] as? NSString)?.doubleValue,
			let windsSpeed = JSON["windSpeed"] as? String,
			let sunsetTime = JSON["sunset"] as? NSDateComponents,
			let sunriseTime = JSON["sunrise"] as? NSDateComponents,
			let visibility = JSON["visibility"] as? String,
			let windsDirection = JSON["windDirection"] as? String,
			let humidity = JSON["humidity"] as? String,
			let condition = JSON["condition"] as? String
		else { return nil }
		self.temprature = Int(round(temprature))
		self.pressure = pressure
		self.windTemperatue = Int(round(windTemperatue))
		self.sunriseTime = sunriseTime
		self.sunsetTime = sunsetTime
		self.visibility = visibility
		self.windsDirection = windsDirection
		self.humidity = humidity
		self.windsSpeed = windsSpeed
		self.condition = WeatherCondition(rawValue: condition)
	}
}