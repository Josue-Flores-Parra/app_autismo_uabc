flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks .flutter-plugins .flutter-plugins-dependencies
cd ..
flutter pub get
cd ios
pod install
cd ..