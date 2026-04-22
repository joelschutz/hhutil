# This file builds releases for the application

target="tarot"

if [ "$PWD" = "$(realpath "../hhutil/")" ]; then
  cd "$target-game"
fi

rm -r $target
rm game.love

# Make File Structure
mkdir $target

# Build love2d bundle
zip -9 -r game.love . -x "*$target/*" screenshot.png "*.vscode/*" "*.aseprite*" "*.zip*" "*.sfd*" "*.md*" "*lib/*" "*.sh*"

# Copies release files
cp -rva licenses $target
cp -va game.love $target