//
//  WeatherUnit.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum WeatherUnit {
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
			internalJSON[eachKey] = WeatherUnit.convert((JSON[eachKey] as? Double) ?? -1, from: .Fahrenheit, to: self)
		}
		
		return internalJSON
	}
	
	private static func convert(value: Double, from funit: WeatherUnit, to tunit: WeatherUnit) -> Double? {
		switch (funit, tunit) {
		case (funit, funit):
			return value
		case (.Fahrenheit, .Celsius):
			return (value - 32) / 1.8
		case (.Celsius, .Fahrenheit):
			return value * 1.8 + 32
//		case (.Mi, .Km):
//			return value / 1000
//		case (.Km, .Mi):
//			return value * 1000
		default:
			return nil
		}
	}
}