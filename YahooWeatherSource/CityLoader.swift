//
//  CityLoader.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct CityLoader: WeatherSourceProtocol {
	let sql: WeatherSourceSQL
	
	public init(input: String) {
		let baseSQL: WeatherSourceSQLPatterns = .city
		sql = baseSQL.generateSQL(with: input)
	}
	
	public func loads(complete: ([City]) -> Void) {
		sendRequst(sql) {
			guard let citiesJSON = $0 as? NSDictionary else {
				complete([])
				return
			}
			let unwrapped: [NSDictionary]
			if let places = (citiesJSON["query"] as? NSDictionary)?["results"]?["place"] as? [NSDictionary] {
				unwrapped = places
			} else if let place = (citiesJSON["query"] as? NSDictionary)?["results"]?["place"] as? NSDictionary {
				unwrapped = [place]
			} else {
				complete([])
				return
			}
			let cities = unwrapped.flatMap { City(from: $0) }
			complete(cities)
		}
	}
}