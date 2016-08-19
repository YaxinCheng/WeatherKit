//
//  WeatherCondition.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-07-28.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct WeatherCondition {
	public let rawValue: String
	
	public init(rawValue: String) {
		
		let initializer: (String) -> (String) = {
			if let range = $0.rangeOfString(" (day)") {
				return $0.stringByReplacingCharactersInRange(range, withString: "")
			} else if let range = $0.rangeOfString(" (night)") {
				return $0.stringByReplacingCharactersInRange(range, withString: "")
			} else {
				return $0
			}
		}
		self.rawValue = initializer(rawValue)
	}
}