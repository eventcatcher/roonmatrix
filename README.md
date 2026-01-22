# RoonMatrix

This app is the frontend for the RoonMatrix LED-Matrix an CoverPlayer Hardware.
The RoonMatrix is a LED display with multiple 8x8 LED matrix modules in a row, controlled by a raspberry zero 2w controller, with a few additional hardware buttons.

With this RoonMatrix device its possible to control the playout, and display on the LED-Matrix what is playing on Apple Music or Spotify (via local running Webserver of the Computer, the Music Software is running on) or a Roon Server.
To complete the possibilities, you can add additional sources which will be output as text to the LED Matrix device too, like RSS Feeds from different sources, actual Weather, Date and Time.

The app scans a ip range to search for RoonMatrix displays in a local network, displays the base config data of each device in a list, like device name, ip address, control zone, and number of playouts, and which text will be displayed on the LED matrix at the moment.
The app can display the actual variables of the python script which is running on the raspberry zero, the configuration data, and the log data.
On the control page can you select which roon zone, Apple Music or Spotify app you will control with the buttons.
With the buttons you can control the playout of the Music Software (next track, previous track, play, pause, shuffle) like the hardware buttons on the RoonMatrix device.

The RoonMatrix app is build with Flutter, Dart, and Visual Code, a fine cross platform programming environment.
With this source code its possible, supported, and tested to build executable code for Apple iOS (iPhone, iPad), Android, MacOS (Universal), Windows (x64) and Linux (Arm / x64).

## Linux

The recommended way to run RoonMatrix on Linux is the AppImage.
It does not require installation and supports hardware-accelerated graphics
(including NVIDIA).

Download:
https://github.com/eventcatcher/roonmatrix/releases/latest
