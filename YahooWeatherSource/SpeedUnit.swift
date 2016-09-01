//
//  SpeedUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-30.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum SpeedUnit: WeatherUnitProtocol {
	case mph
	case kmph
	typealias valueType = Dictionary<String, AnyObject>
	
	func convert(value: valueType) -> valueType {
		let speedKey = "windSpeed"
		guard self == kmph, let windSpeed = value[speedKey] as? Double else { return value }
		let convertedSpeed = convert(windSpeed, from: mph, to: kmph)
		var convertedJSON = value
		convertedJSON[speedKey] = convertedSpeed
		return convertedJSON
	}
	
	private func convert(value: Double, from funit: SpeedUnit, to tunit: SpeedUnit) -> Double {
		switch (funit, tunit) {
		case (mph, kmph):
			return value / 1000
		case (kmph, mph):
			return value * 1000
		default:
			return value
		}
	}
}