Pod::Spec.new do |spec|
  spec.name = "YahooWeatherSource"
  spec.version = "1.0.0"
  spec.summary = "Simple swift framework loads weather information from Yahoo"
  spec.homepage = "https://github.com/yaxincheng/yahooweathersource"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Your Name" => 'yaxin.cheng@dal.ca' }
  spec.social_media_url = "https://www.facebook.com/yaxCheng"

  spec.platform = :ios, "9.1"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/yaxincheng/yahooweathersource.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "YahooWeatherSource/**/*.{h,swift}"
end