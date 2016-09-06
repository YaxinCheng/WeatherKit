//
//  DirectionUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-30.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum DirectionUnit {
	case degree
	case direction
	typealias valueType = Dictionary<String, AnyObject>
	
	/**
	Convert distance unit in weather json or forecast json
	- Parameter value: json needs to be converted
	*/
	func convert(value: valueType) -> valueType {
		let directionKey = "windDirection"
		guard self == .direction, let windDirection = (value[directionKey] as? NSString)?.doubleValue else { return value }
		
		let windDegree: Double
		if windDirection < 0 {
			windDegree = 360 + windDirection
		} else if windDirection > 360 {
			windDegree = Double(Int(windDirection) % 360)
		} else {
			windDegree = windDirection
		}
		
		let degree = convert(degree: windDegree)
		var convertedJSON = value
		convertedJSON[directionKey] = degree
		return convertedJSON
	}
	
	/**
	Convert a value from one distance unit to another direction unit
	- Parameter windDegree: The wind degree needs to be converted
	*/
	private func convert(degree windDegree: Double) -> String {
		let deviation = 11.25
		switch windDegree {
		case let degree where degree >= 31 * deviation && degree < deviation:
			return "N"
		case let degree where degree < 3 * deviation:
			return "NNE"
		case let degree where degree < 5 * deviation:
			return "NE"
		case let degree where degree < 7 * deviation:
			return "ENE"
		case let degree where degree < 9 * deviation:
			return "E"
		case let degree where degree < 11 * deviation:
			return "ESE"
		case let degree where degree < 13 * deviation:
			return "S"
		case let degree where degree < 15 * deviation:
			return "SSE"
		case let degree where degree < 17 * deviation:
			return "S"
		case let degree where degree < 19 * deviation:
			return "SSW"
		case let degree where degree < 21 * deviation:
			return "SW"
		case let degree where degree < 23 * deviation:
			return "WSW"
		case let degree where degree < 25 * deviation:
			return "W"
		case let degree where degree < 27 * deviation:
			return "WNW"
		case let degree where degree < 29 * deviation:
			return "NW"
		default:
			return "DEGREE ERROR"
		}
	}
}