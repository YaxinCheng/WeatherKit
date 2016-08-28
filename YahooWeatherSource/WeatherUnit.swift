//
//  WeatherUnit.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

protocol WeatherUnit {
	func convert(JSON: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject>
}