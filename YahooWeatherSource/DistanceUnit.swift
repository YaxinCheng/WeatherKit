//
//  DistanceUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum DistanceUnit: WeatherUnitProtocol {
	case mi
	case km
	typealias valueType = Dictionary<String, AnyObject>
	
	func convert(value: valueType) -> valueType {
		let distanceKey = "visibility"
		guard self == .km, let visibility = value[distanceKey] as? Double else { return value }
		var convertedJSON = value
		let convertedVisibility = convert(value: visibility, from: .mi, to: .km)
		convertedJSON[distanceKey] = convertedVisibility
		return convertedJSON
	}
	
	private func convert(value value: Double, from funit: DistanceUnit, to tunit: DistanceUnit) -> Double {
		switch (funit, tunit) {
		case (.mi, .km):
			return value / 1000
		case (.km, .mi):
			return value * 1000
		default:
			return value
		}
	}
}