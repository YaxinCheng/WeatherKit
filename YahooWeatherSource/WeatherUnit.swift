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
	case Mi
	case Km
	
	func convert(JSON: NSDictionary) -> NSDictionary	{
		let internalJSON = JSON.mutableCopy() as! NSMutableDictionary
		switch self {
		case .Celsius:
			internalJSON["temperature"] = WeatherUnit.convert((JSON["temperature"] as? Double) ?? -1, from: self, to: .Fahrenheit)
			internalJSON["windChill"] = WeatherUnit.convert((JSON["windChill"] as? Double) ?? -1, from: self, to: .Fahrenheit)
		case .Fahrenheit:
			internalJSON["temperature"] = WeatherUnit.convert((JSON["temperature"] as? Double) ?? -1, from: self, to: .Celsius)
			internalJSON["windChill"] = WeatherUnit.convert((JSON["windChill"] as? Double) ?? -1, from: self, to: .Celsius)
		default:
			return JSON
		}
		return internalJSON
	}
	
	private static func convert(value: Double, from funit: WeatherUnit, to tunit: WeatherUnit) -> Double? {
		switch (funit, tunit) {
		case (.Fahrenheit, .Celsius):
			return (value - 32) / 1.8
		case (.Celsius, .Fahrenheit):
			return value * 1.8 + 32
		case (.Mi, .Km):
			return value / 1000
		case (.Km, .Mi):
			return value * 1000
		case (funit, funit):
			return value
		default:
			return nil
		}
	}
}