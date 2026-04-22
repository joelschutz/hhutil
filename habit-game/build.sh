# This file builds releases for the application

target="habit"

if [ "$PWD" = "$(realpath "../hhutil/")" ]; then
  cd "$target-game"
fi

rm -rf $target
rm game.love

# Make File Structure
mkdir $target

# Build love2d bundle
zip -9 -r game.love . -x "*$target/*" screenshot.png "*.vscode/*" "*.aseprite*" "*.zip*" "*.sfd*" "*.md*" "*lib/*" "*.sh*"

# Copies release files
cp -va game.love $target
if [ -d licenses ]; then
  cp -rva licenses $target
fi