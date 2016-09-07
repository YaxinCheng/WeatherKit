//
//  DistanceUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum DistanceUnit {
	case mi
	case km
	
	/**
	Convert distance unit in weather json or forecast json
	- Parameter value: json needs to be converted
	*/
	func convert(value: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		let distanceKey = "visibility"
		guard self == .km, let visibility = value[distanceKey] as? Double else { return value }
		var convertedJSON = value
		let convertedVisibility = convert(value: visibility, from: .mi, to: .km)
		convertedJSON[distanceKey] = convertedVisibility
		return convertedJSON
	}
	
	/**
	Convert a value from one distance unit to another distance unit
	- Parameter value: A value needs to be converted
	- Parameter funit: The distance unit needs to be converted from
	- Parameter tunit: The distance unit needs to be converted to
	*/
	private func convert(value value: Double, from funit: DistanceUnit, to tunit: DistanceUnit) -> Double {
		switch (funit, tunit) {
		case (.mi, .km):
			return value * 1.61
		case (.km, .mi):
			return value / 1.61
		default:
			return value
		}
	}
}