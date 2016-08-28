//
//  TemperatureUnit.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum TemperatureUnit: WeatherUnit {
	case Fahrenheit
	case Celsius
	
	func convert(JSON: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject>	{
		if case .Fahrenheit = self {
			return JSON
		}
		var internalJSON = JSON
		let weatherMode = JSON["temperature"] is Double
		let tempKeys = weatherMode ? ["temperature", "windChill"] : ["high", "low"]
		for eachKey in tempKeys {
			internalJSON[eachKey] = convert((JSON[eachKey] as? Double) ?? -1, from: .Fahrenheit, to: self)
		}
		
		return internalJSON
	}
	
	private func convert(value: Double, from funit: TemperatureUnit, to tunit: TemperatureUnit) -> Double {
		switch (funit, tunit) {
		case (.Fahrenheit, .Celsius):
			return (value - 32) / 1.8
		case (.Celsius, .Fahrenheit):
			return value * 1.8 + 32
		default:
			return value
		}
	}
}