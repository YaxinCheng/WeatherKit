//
//  TemperatureUnit.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum TemperatureUnit {
	case fahrenheit
	case celsius
	typealias valueType = Dictionary<String, AnyObject>
	
	/**
	Convert temperature unit in weather json or forecast json
	- Parameter value: json needs to be converted
	*/
	func convert(value: valueType) -> valueType	{
		if case .fahrenheit = self {
			return value
		}
		var internalJSON = value
		let weatherMode = value["temperature"] is Double
		let tempKeys = weatherMode ? ["temperature", "windChill"] : ["high", "low"]
		for eachKey in tempKeys {
			internalJSON[eachKey] = convert((value[eachKey] as? Double) ?? -1, from: .fahrenheit, to: self)
		}
		return internalJSON
	}
	
	/**
	Convert a value from one temperature unit to another temperature unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The unit needs to be converted from
	- Parameter tunit: The unit needs to be converted to
	*/
	private func convert(value: Double, from funit: TemperatureUnit, to tunit: TemperatureUnit) -> Double {
		switch (funit, tunit) {
		case (.fahrenheit, .celsius):
			return (value - 32) / 1.8
		case (.celsius, .fahrenheit):
			return value * 1.8 + 32
		default:
			return value
		}
	}
}