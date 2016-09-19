//
//  String+numberValue.swift
//  WeatherKit
//
//  Created by Yaxin Cheng on 2016-09-19.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

extension String {
	var doubleValue: Double? {
		return Double(self)
	}
	
	var integerValue: Int? {
		return Int(self)
	}
}
