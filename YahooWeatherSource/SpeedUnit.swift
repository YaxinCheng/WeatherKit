//
//  SpeedUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-30.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum SpeedUnit {
	case mph
	case kmph
	
	/**
	Convert distance unit in weather json or forecast json
	- Parameter value: json needs to be converted
	*/
	func convert(value: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		let speedKey = "windSpeed"
		guard self == kmph, let windSpeed = value[speedKey] as? Double else { return value }
		let convertedSpeed = convert(windSpeed, from: mph, to: kmph)
		var convertedJSON = value
		convertedJSON[speedKey] = convertedSpeed
		return convertedJSON
	}
	
	/**
	Convert a value from one distance unit to another speed unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The speed unit needs to be converted from
	- Parameter tunit: The speed unit needs to be converted to
	*/
	private func convert(value: Double, from funit: SpeedUnit, to tunit: SpeedUnit) -> Double {
		switch (funit, tunit) {
		case (mph, kmph):
			return value * 1.61
		case (kmph, mph):
			return value / 1.61
		default:
			return value
		}
	}
}