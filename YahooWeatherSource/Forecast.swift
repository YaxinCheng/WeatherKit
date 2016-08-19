//
//  Forecast.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-05.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct Forecast {
	public var highTemp: Double
	public var lowTemp: Double
	public let condition: WeatherCondition
	public let conditionDescription: String
	public let date: String
	
	public init?(with JSON: NSDictionary) {
		guard
			let time = JSON["date"] as? String,
			let date = NSDate.date(string: time, format: "dd MMM yyyy"),
			let high = (JSON["high"] as? NSString)?.doubleValue,
			let low = (JSON["low"] as? NSString)?.doubleValue,
			let conditionString = JSON["text"] as? String
		else { return nil }
		self.date = date.formatDate()
		conditionDescription = conditionString
		highTemp = high
		lowTemp = low
		condition = WeatherCondition(rawValue: conditionString)
	}
}