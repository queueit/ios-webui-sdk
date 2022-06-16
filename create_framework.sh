xcodebuild build -scheme QueueITLib -derivedDataPath ./builds/simulator -arch x86_64 -sdk iphonesimulator \
  && xcodebuild build -scheme QueueITLib -derivedDataPath ./builds/ios -sdk iphoneos \
  && xcodebuild build -scheme QueueITLib -derivedDataPath ./builds/simulator-arm64 -arch arm64 -sdk iphonesimulator \
  && lipo -create builds/simulator/Build/Products/Debug-iphonesimulator/libQueueITLib.a \
      builds/simulator-arm64/Build/Products/Debug-iphonesimulator/libQueueITLib.a \
      -output builds/simulator/libQueueITLib.a \
  && mkdir dist \
  && xcodebuild -create-xcframework \
        -library builds/ios/Build/Products/Debug-iphoneos/libQueueITLib.a \
        -headers builds/ios/Build/Products/Debug-iphoneos/include/QueueITLib \
        -library builds/simulator/libQueueITLib.a \
        -headers builds/simulator/Build/Products/Debug-iphonesimulator/include/QueueITLib \
        -output dist/QueueITLib.xcframework \
  && cd dist \
  && zip -r -X QueueITLib.xcframework.zip QueueITLib.xcframework