//
//  NSDateComponents+InitFromString.swift
//  YahooWeatherSource
//
//  Created by Yaxin Cheng on 2016-08-23.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

extension NSDateComponents {
	convenience init?(from timeString: String) {
		self.init()
		let timeComponents = timeString.characters.split(isSeparator: {$0 == " " || $0 == ":"}).map(String.init)
		guard timeComponents.count >= 2 else { return nil }
		let elements = timeComponents.flatMap { Int($0) }
		self.hour = elements[0] + (timeComponents[2] == "am" ? 0 : 12)
		self.minute = elements[1]
	}
}