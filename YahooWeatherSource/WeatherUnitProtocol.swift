//
//  WeatherUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

protocol WeatherUnitProtocol {
	/**
	Associated value type needs to be converted
	*/
	associatedtype valueType
	/**
	Convert the value with this type to another value
	*/
	func convert(value: valueType) -> valueType
}