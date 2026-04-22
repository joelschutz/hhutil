# This file builds releases for all the application

# Create Release directory
rm -r release
mkdir release

# Loop over the apps
for app in "weather" "calc" "metronome" "dice" "tarot" "todo" "gptester" "habit"; do
    sh ./$app-game/build.sh # Builds app
    mkdir release/$app
    cp -rva ./$app-game/$app ./release/$app/$app/ # Copy files to release dir
    cp -rva ./$app-game/README.md ./release/$app/$app/ # Copy README.md to release dir
    cp -rva ./$app-game/port.json ./release/$app/$app/ # Copy port.json to release dir
    cp -rva ./$app-game/screenshot.png ./release/$app/$app/ # Copy screenshot.png to release dir
    cp -rva ./$app-game/gameinfo.xml ./release/$app/$app/ # Copy gameinfo.xml to release dir
    sed "s/PLACEHOLDER/$app/g" example.sh > ./release/$app/$(echo "$app" | sed 's/./\U&/').sh # Generate Portmaster script
    cd ./release/$app
    zip -9 -r $app .
    cd ../..
done
