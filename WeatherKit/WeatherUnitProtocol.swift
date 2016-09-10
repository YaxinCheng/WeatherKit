//
//  WeatherUnitProtocol.swift
//  WeatherKit
//
//  Created by Yaxin Cheng on 2016-09-10.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

protocol WeatherUnitProtocol {
	associatedtype ValueType
	func convert(value: Double, from funit: Self, to tunit: Self) -> ValueType
}

extension WeatherUnitProtocol {
	/**
	An open access for unit conversion functions
	- Parameter value: A value needs to be converted
	- Parameter funit: The unit needs to be converted from
	- Parameter tunit: The unit needs to be converted to
	*/
	func convert(value: Double, from funit: Self, to tunit: Self) -> ValueType {
		switch funit.self {
		case is TemperatureUnit:
			return convertValue(value, from: funit as! TemperatureUnit, to: tunit as! TemperatureUnit) as! ValueType
		case is DistanceUnit:
			return convertValue(value, from: funit as! DistanceUnit, to: tunit as! DistanceUnit) as! ValueType
		case is SpeedUnit:
			return convertValue(value, from: funit as! SpeedUnit, to: tunit as! SpeedUnit) as! ValueType
		case is DirectionUnit:
			return convertValue(value, from: funit as! DirectionUnit, to: tunit as! DirectionUnit) as! ValueType
		default:
			fatalError()
		}
	}
	/**
	Convert a value from one temperature unit to another temperature unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The unit needs to be converted from
	- Parameter tunit: The unit needs to be converted to
	*/
	private func convertValue(value: Double, from funit: TemperatureUnit, to tunit: TemperatureUnit) -> Double {
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
	private func convertValue(value: Double, from funit: DistanceUnit, to tunit: DistanceUnit) -> Double {
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
	Convert a value from one distance unit to another speed unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The speed unit needs to be converted from
	- Parameter tunit: The speed unit needs to be converted to
	*/
	private func convertValue(value: Double, from funit: SpeedUnit, to tunit: SpeedUnit) -> Double {
		switch (funit, tunit) {
		case (.mph, .kmph):
			return value * 1.61
		case (.kmph, .mph):
			return value / 1.61
		default:
			return value
		}
	}
	
	/**
	Convert a value from one distance unit to another direction unit
	- Parameter windDegree: The wind degree needs to be converted
	*/
	private func convertValue(windDegree: Double, from funit: DirectionUnit, to tunit: DirectionUnit) -> String {
		guard funit != tunit else { return "\(windDegree)" }
		guard funit != .direction || tunit != .degree else { return "Unable to load" }
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

}
