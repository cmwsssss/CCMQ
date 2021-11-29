Pod::Spec.new do |spec|

  spec.name         = "CCMQ"
  spec.version      = "1.0.1"
  spec.summary      = "CCMQ is a message queue framework built for iOS"

  spec.description  = <<-DESC
		     CCMQ is a message queue framework built for iOS
                   DESC

  spec.homepage     = "https://github.com/cmwsssss/CCMQ"

  spec.license      = "MIT"

  spec.author       = { "cmw" => "cmwsssss@hotmail.com" }

  spec.platform     = :ios, "6.0"

  spec.source       = { :git => "https://github.com/cmwsssss/CCMQ.git", :tag => "1.0.1" }

  spec.source_files  = "CCMQ", "CCMQ/**/*.{h,m}"
  spec.exclude_files = "CCMQ/Exclude"

end
