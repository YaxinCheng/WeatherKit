//
//  City.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-04.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public struct City: CustomStringConvertible {
	public let name: String
	public let province: String
	public let country: String
	public let woeid: String
	public let latitude: Double
	public let longitude: Double
	public let timeZone: NSTimeZone
	public var region: String {
		return province.isEmpty ? country : province + ", " + country
	}
	
	public init?(from JSON: NSDictionary) {
		guard
			let name = JSON["name"] as? String,
			let country = JSON["country"] as? String,
			let woeid = JSON["woeid"] as? String,
			let province = JSON["admin1"] as? String,
			let latitude = (JSON["centroid"]?["latitude"] as? NSString)?.doubleValue,
			let longitude = (JSON["centroid"]?["longitude"] as? NSString)?.doubleValue,
			let timeZoneString = JSON["timezone"] as? String,
			let timeZone = NSTimeZone(name: timeZoneString)
		else { return nil }
		self.name = name
		self.woeid = woeid
		self.country = country
		self.province = province
		self.latitude = latitude
		self.longitude = longitude
		self.timeZone = timeZone
	}
	
	public var description: String {
		return name + ", " + region
	}
}