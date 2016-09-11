//
//  TemperatureUnit.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TemperatureUnit: WeatherUnitProtocol {
	case fahrenheit
	case celsius
	public typealias ValueType = Double
	/**
	Convert temperature unit in weather json or forecast json
	- Parameter value: json needs to be converted
	*/
	func convert(value: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject>	{
		if case .fahrenheit = self {
			return value
		}
		var internalJSON = value
		let weatherMode = value["temperature"] is Double
		let tempKeys = weatherMode ? ["temperature", "windChill"] : ["high", "low"]
		for eachKey in tempKeys {
			internalJSON[eachKey] = convert((value[eachKey] as? Double) ?? -1, from: TemperatureUnit.fahrenheit, to: self)
		}
		return internalJSON
	}
	
	public var description: String {
		return self == .celsius ? "°C" : "°F"
	}
}