# SteakEngine

had to make the original CharlieEngine repo a template because i didnt want to modify that one!

anyway rebranded as SteakEngine
- this is meant to be a thing where you can make scripts using lua to mod cts, but im still figuring out how to do stuff within objective c++ itself i havent got to the lua part yet

# install instructions
### prerequisities
- your brain
- anything that lets you sideload ipas to your phone
- anything that lets you inject dynamic libraries to ipas (ios applications)
- (sideloadly does both btw and doesnt require jailbreak)
### install steps
1. go to releases and download libSteakEngine.dylib and download [Info.plist](https://github.com/YellowCat98/SteakEngine/blob/main/Info.plist)
2. install charlie the steak ipa
3. unzip the ipa (its just a zip file), go to Payload/The Steak-iphone folder
4. Replace Info.plist with the one you downloaded.
5. Zip the IPA back up
6. Inject the IPA with libSteakEngine.dylib
7. Sideload the IPA.
8. have fun

# building
- this requires a mac btw
- im building the project entirely with github actions, which already has all required tools installed.
- make sure you have xcode and git installed obviously!!
- anyway
1. clone this repo
2. run build.sh
3. should be a libSteakEngine.dylib at ProjectRoot/build/Release-iphoneos/
4. that is your dylib! (ignore libLua.a btw)

(this thing is mainly meant for fun btw, please do not make any illegal things with this thing!)