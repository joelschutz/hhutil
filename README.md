# hhUtil

This project name stands for *Handheld Utilities* and aims to provide a compreensive list of utility aplications for handheld consoles compatible with Portmaster. To insure compatibility, all apps are limited to a 4:3(640x480) resolution and do not require analog inputs, although those are mapped to d-pad inputs.

## Available Apps

- Calculator
- Dice Roller
- Metronome
- Weather Forecast
- To-Do List
- Calendar(Soon)
- Controller Tester
- Habit Tracker
- Tarot

## Motivations
Those new low cost handheld consoles are a very popular and although they are limited in performance, this is also a feature in my understanding to keep this platform free as in freedom. Those consoles are a chance for more young users to have their first experience with FOSS(Free and Open Source Software) and thats great! The scene around these are a kind of crossover between linux and homebrew, but not much apart from games are developed for those.
This project tries to be a compromise that could help bridges gaming and utility, all apps are build entirelly with love2d, the legendary game library for homebrew. My objective is to create more utility software that, instead of mouse and keyboard, will be primarely used with a controller. I hope more developers get inspired by my vision and try there own solutions to make those small consoles even more useful.

## Contribution

To contribute you must first open an Issue with your suggestions and then open a PR with the modifications for review. To contribute first you must clone this repo:

```sh
git clone github.com/joelschutz/hhutil
```

To create a new build of some app, please use the provided build script on the folder of the app. To build the Calculator, try:

```sh
cd calc-game
sh build.sh
```

To build all apps at the same time, you can use the `build-all.sh` script at the root of the repository. This script also package the application for PortMaster install.

Note: If you are building this apps on **Windows** you must use `WSL` or build then manually.

## TODO

- [ ] Adds Translations
- [ ] Refactor for standard interface
- [ ] Standardize palletes when possible
- [X] Adds Licensing and Credits to assets folders
- [X] Adds Metadata for PortMaster

## Licensing

This project is distributed under the GNU GPL.

This project uses some third party assets and all apropriate credits and licenses are distrbuted together and must not be deleted. Keep in mind the GNU GPL license of this project only applies to it's codebase, all third party assets and libraries have different licenses applied.