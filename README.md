# RoonMatrix

This app is the frontend to control the following devices:

Roonmatrix, a free Maker project: a device with a big LED matrix display (multiple 8x8 LED matrix modules in a row), controlled by a raspberry zero 2w controller, with a few additional hardware buttons. 

Coverplayer, a free maker project: a small touch-controlled device with a square color LCD display to present the album cover, selecting the zone, controlling the playback mode, and searching the music libraries.

With the RoonMatrix and CoverPlayer device its possible to control the playout, and display what is playing on Apple Music or Spotify (via local running Webserver of the Computer, the Music Software is running on) or a Roon Server.
Spotify Connect is supported too (works without Webserver).

The Coverplayer has a focus on Music.

The RoonMatrix has the option to display additional informations from different sources on the LED Matrix stream, like RSS Feeds from different sources, actual Weather, Date and Time, or own messages send with the app to the device.

The app scans a ip range to search for RoonMatrix and Coverplayer devices in a local network, displays the base config data of each device in a list, like device name, ip address, control zone, and number of playouts, and which text will be displayed on the screen.

Config Page: On this page you can setup a device and define what sources and types of data you will collect to a stream which will be displayed on the devices screen: What Music Sources you will use (Roon, Apple Music, Spotify, Spotify Connect), Virtual Keyboard Layout, Language Translation, Weather parameters, Webserver URLs, Bluetooth Audio paraemeters, RSS feeds, clock config and many many more. On another tab you can display the actual configuration data of the device.

Control Page: The cover of the actual selected source is displayed here. And you can select which roon zone, Apple Music or Spotify sources you will control with the buttons.
With the buttons you can control the playout of the Music Software (next track, previous track, play, pause, shuffle) like the hardware buttons on the RoonMatrix device.

Message Page (RoonMatrix only): Here you can write messages which will be send to the device. The device will include this message into the displayed text stream. You can save messages as presets too.

LiveControl Page (RoonMatrix only): On this page you can set the brightness and speed of the LED matrix text stream in real time.

Log Page: Display the log data of the device. You can read the last hour or more, and use the search filter to find things of interest. Export to file is also possible. 

The RoonMatrix app is build with Flutter, Dart, and Visual Code, a fine cross platform programming environment.
With this source code its possible, supported, and tested to build executable code for Apple iOS (iPhone, iPad), Android, MacOS (Universal), Windows (x64) and Linux (Arm / x64).

## Linux

The recommended way to run RoonMatrix on Linux is the AppImage.
It does not require installation and supports hardware-accelerated graphics
(including NVIDIA).

Download:
https://github.com/eventcatcher/roonmatrix/releases/latest
