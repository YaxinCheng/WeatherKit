//
//  WeatherSourceProtocol.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

protocol WeatherSourceProtocol {
	var api: String { get }
	var format: String { get }
}

extension WeatherSourceProtocol {
	var api: String {
		return "https://query.yahooapis.com/v1/public/yql?q="
	}
	
	var format: String {
		return "&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
	}
	
	func sendRequst(sql: WeatherSourceSQL, with completion: (Any?)->()) {
		guard let url = NSURL(string: api + sql.rawValue + format) else {
			completion("URL Error")
			return
		}
		let urlRequest = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10 * 60)
		urlRequest.HTTPMethod = "GET"
		NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { (data, response, error) in
			if error != nil {
				completion(error!)
			} else {
				do {
				guard let responseData = data,
					let JSON = try NSJSONSerialization.JSONObjectWithData(responseData, options: .MutableLeaves) as? Dictionary<String, AnyObject> where JSON["error"] == nil else {
						completion("Internal Error")
						return
					}
					completion(JSON)
				} catch {
					completion(error)
				}
			}
		}.resume()
	}
}
