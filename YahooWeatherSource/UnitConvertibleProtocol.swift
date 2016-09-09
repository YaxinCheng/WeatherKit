//
//  UnitConvertibleProtocol.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-09-09.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public protocol UnitConvertibleProtocol {
}

extension UnitConvertibleProtocol {
	/**
	Convert a value from one temperature unit to another temperature unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The unit needs to be converted from
	- Parameter tunit: The unit needs to be converted to
	*/
	public func convert(value: Double, from funit: TemperatureUnit, to tunit: TemperatureUnit) -> Double {
		switch (funit, tunit) {
		case (.fahrenheit, .celsius):
			return (value - 32) / 1.8
		case (.celsius, .fahrenheit):
			return value * 1.8 + 32
		default:
			return value
		}
	}
	
	/**
	Convert a value from one distance unit to another distance unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The distance unit needs to be converted from
	- Parameter tunit: The distance unit needs to be converted to
	*/
	public func convert(value value: Double, from funit: DistanceUnit, to tunit: DistanceUnit) -> Double {
		switch (funit, tunit) {
		case (.mi, .km):
			return value * 1.61
		case (.km, .mi):
			return value / 1.61
		default:
			return value
		}
	}
	
	/**
	Convert a value from one distance unit to another direction unit
	- Parameter windDegree: The wind degree needs to be converted
	*/
	public func convert(degree windDegree: Double) -> String {
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
			return "NNW"
		}
	}
	
	/**
	Convert a value from one distance unit to another speed unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The speed unit needs to be converted from
	- Parameter tunit: The speed unit needs to be converted to
	*/
	public func convert(value: Double, from funit: SpeedUnit, to tunit: SpeedUnit) -> Double {
		switch (funit, tunit) {
		case (.mph, .kmph):
			return value * 1.61
		case (.kmph, .mph):
			return value / 1.61
		default:
			return value
		}
	}
}