//
//  DistanceUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum DistanceUnit: WeatherUnit {
	case mi
	case km
	
	func convert(JSON: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
		if case .mi = self { return JSON }
		guard let visibility = JSON["visibility"] as? Double else { return JSON }
		var convertedJSON = JSON
		let convertedVisibility = convert(value: visibility, from: .mi, to: .km)
		convertedJSON["visibility"] = convertedVisibility
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