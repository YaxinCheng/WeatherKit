//
//  WeatherUnit.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum WeatherUnit {
	case Fahrenheit
	case Celsius
	case Mi
	case Km
	
	private static func convert(value: Double, from funit: WeatherUnit, to tunit: WeatherUnit) -> Double? {
		switch (funit, tunit) {
		case (.Fahrenheit, .Celsius):
			return (value - 32) / 1.8
		case (.Celsius, .Fahrenheit):
			return value * 1.8 + 32
		case (.Mi, .Km):
			return value / 1000
		case (.Km, .Mi):
			return value * 1000
		default:
			return nil
		}
	}
}