//
//  WeatherSourceSQL.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

struct WeatherSourceSQL: StringLiteralConvertible {
	var rawValue: String
	typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
  typealias UnicodeScalarLiteralType = UnicodeScalar
  
  init(rawValue: String) {
    self.rawValue = WeatherSourceSQL.stringMappingSQL(rawValue)
  }
  
  init(stringLiteral value: StringLiteralType) {
    rawValue = WeatherSourceSQL.stringMappingSQL(value)
  }
  
  init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
    rawValue = WeatherSourceSQL.stringMappingSQL(value)
  }
  
  init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
    rawValue = WeatherSourceSQL.stringMappingSQL("\(value)")
  }
	
	static func stringMappingSQL(rawValue: String) -> String {
		var mappedString: String = ""
		for each in rawValue.characters {
			switch each {
			case " ":
				mappedString += "%20"
			case "\"":
				mappedString += "%22"
			case ",":
				mappedString += "%2C"
			case "=":
				mappedString += "%3D"
			default:
				mappedString += String(each)
			}
		}
		return mappedString
	}
}