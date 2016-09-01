//
//  Result.swift
//  Weather
//
//  Created by Yaxin Cheng on 2016-07-29.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum Result<T> {
	case Success(T)
	case Failure(ErrorType)
	
	init(error: ErrorType) {
		self = Result.Failure(error)
	}
	
	init(value: T) {
		self = Result.Success(value)
	}
}