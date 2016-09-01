//
//  WeatherSourceSQL.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-08-12.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

enum WeatherSourceSQL: String {
	case weather = "select wind, atmosphere, item.condition, astronomy from weather.forecast where woeid = \"%@\""
	case forecast = "select item.forecast from weather.forecast where woeid = \"%@\""
	case cityFromName = "select name, country.content,admin1.content,woeid,centroid,timezone.content from geo.places where text=\"%@\""
	case cityFromWoeid = "select name, country.content,admin1.content,woeid,centroid,timezone.content from geo.places where woeid=\"%@\""
	case daytime = "select astronomy from weather.forecast where woeid = \"%@\""
	
	func execute(information info: String, ignoreCache: Bool = false, completion: (Result<Dictionary<String, AnyObject>>) -> Void) {
		let api = "https://query.yahooapis.com/v1/public/yql?q="
		let endPoint = "&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
		let sql = String(format: rawValue, info)
		guard
			let encodedString = (api + sql + endPoint).stringByAddingPercentEncodingWithAllowedCharacters(.URLFragmentAllowedCharacterSet()),
			let requestURL = NSURL(string: encodedString)
		else {
			completion(Result<Dictionary<String, AnyObject>>(error: WeatherSourceSQLError.URLError))
			return
		}
		let request = NSMutableURLRequest(URL: requestURL, cachePolicy: ignoreCache ? .ReloadIgnoringLocalCacheData : .UseProtocolCachePolicy, timeoutInterval: ignoreCache ? 0 : 10 * 60)
		request.HTTPMethod = "GET"
		NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
			if error != nil {
				let errorResult = Result<Dictionary<String, AnyObject>>(error: error!)
				completion(errorResult)
			} else {
				do {
					guard let responseData = data,
						let JSON = try NSJSONSerialization.JSONObjectWithData(responseData, options: .MutableLeaves) as? Dictionary<String, AnyObject> where JSON["error"] == nil else {
							let errorResult = Result<Dictionary<String, AnyObject>>(error: WeatherSourceSQLError.InternalError)
							completion(errorResult)
							return
					}
					let result = Result<Dictionary<String, AnyObject>>(value: JSON)
					completion(result)
				} catch {
					let errorResult = Result<Dictionary<String, AnyObject>>(error: WeatherSourceSQLError.JSONSerializeError)
					completion(errorResult)
				}
			}
		}.resume()
	}
}

enum WeatherSourceSQLError: ErrorType {
	case URLError
	case InternalError
	case JSONSerializeError
}