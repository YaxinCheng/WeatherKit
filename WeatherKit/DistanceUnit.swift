//
//  DistanceUnit.swift
//  WeatherKit
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum DistanceUnit: WeatherUnitProtocol {
	case mi
	case km
	public typealias ValueType = Double
	/**
	Convert distance unit in weather json or forecast json
	- Parameter value: json needs to be converted
	*/
	func convert(_ value: Dictionary<String, Any>) -> Dictionary<String, Any> {
		let distanceKey = "visibility"
		guard self == .km, let visibility = value[distanceKey] as? Double else { return value }
		var convertedJSON = value
		let convertedVisibility = convert(visibility, from: DistanceUnit.mi, to: DistanceUnit.km)
		convertedJSON[distanceKey] = convertedVisibility
		return convertedJSON
	}
	
	public var description: String {
		return self == .mi ? "MI" : "KM"
	}
}
