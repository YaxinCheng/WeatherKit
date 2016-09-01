//
//  WeatherUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

protocol WeatherUnitProtocol {
	associatedtype valueType
	func convert(value: valueType) -> valueType
}