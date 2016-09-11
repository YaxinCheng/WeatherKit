//
//  SpeedUnit.swift
//  WeatherKit
//
//  Created by Yaxin Cheng on 2016-08-30.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum SpeedUnit: WeatherUnitProtocol {
	case mph
	case kmph
	public typealias ValueType = Double
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
	
	public var description: String {
		return self == .mph ? "MPH" : "KMPH"
	}
}