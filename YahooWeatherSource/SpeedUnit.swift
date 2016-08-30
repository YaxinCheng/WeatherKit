//
//  SpeedUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-30.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum SpeedUnit: WeatherUnit {
	case mph
	case kmph
	
	func convert(JSON: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		let speedKey = "windSpeed"
		guard self == kmph, let windSpeed = JSON[speedKey] as? Double else { return JSON }
		let convertedSpeed = convert(windSpeed, from: mph, to: kmph)
		var convertedJSON = JSON
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