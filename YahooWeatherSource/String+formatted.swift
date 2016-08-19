//
//  String+formatted.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-18.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

extension String {
	var formatted: String {
		return self.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()).stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale(localeIdentifier: "en_CA")).stringByReplacingOccurrencesOfString(" ", withString: "")
	}
}