# C4 Android Screensaver

## What is it?
This driver replicates official C4 Navigator screensavers by displaying a combination of:
- Time
- Date
- Weather
- Current Media

<img src="https://github.com/13mralex/c4-android-screensaver/blob/main/images/Capture1.PNG?raw=true" width=45%></img>
<img src="https://github.com/13mralex/c4-android-screensaver/blob/main/images/Capture.PNG?raw=true" width=45%></img>
<img width="957" height="703" alt="image" src="https://github.com/user-attachments/assets/6320c5dd-71e9-4255-aa1f-6641098e6849" />
<img width="1041" height="694" alt="image" src="https://github.com/user-attachments/assets/e38bda23-a212-4b3f-8b10-8f15a8221c9f" />
<img width="1042" height="691" alt="image" src="https://github.com/user-attachments/assets/760fdb71-9f66-4cbc-a461-a2b73d06e6aa" />



## How it works:
1. Find an applicable app from the Play Store
   - [This](https://m.apkpure.com/web-screensaver/se.andreasottesen.WebScreensaver) is the one I use
2. The URL is formatted simply as `ip:port/roomId`
   - Default port is 8089
3. That's it! Whenever the room is on, the screensaver will automatically display the current media

## Composer Properties

| Property | Options | Default | Description |
|----------|---------|---------|-------------|
| Debug Mode | Off, Print, Log, Print and Log | Off | Debug output control (auto-off after 5 hours) |
| HTTP Port | 1024-65535 | 8089 | Web server port |
| Time Format | 12 Hour, 24 Hour | 12 Hour | Clock display format |
| Show Time | Yes, No | Yes | Toggle time display |
| Show Date | Yes, No | Yes | Toggle date display |
| Show Weather | Yes, No | Yes | Toggle weather display |
| Show Media | Yes, No | Yes | Toggle media display |
| Display Mode | Normal, Big Clock | Normal | Switch between full display and simple clock |
| Fade Interval | 30 Seconds - 10 Minutes | 1 Minute | Burn-in prevention fade cycle (Big Clock mode) |
| Background Color | Hex color | #000000 | Background color |
| Text Color | Hex color | #FFFFFF | Text color |
| Media Poll Interval | Disabled, 1-10 Seconds, 30 Seconds, 1-3 Minutes | 3 Seconds | How often to check for media changes |
| Settings Poll Interval | Disabled, 5-60 Seconds, 2-5 Minutes | 60 Seconds | How often to check for settings changes |

## Display Modes

### Normal Mode
Full screensaver with time, date, weather, and current media (album art, title, artist).

### Big Clock Mode
Simplified display for minimal controller load:
- Large centered time with AM/PM
- Date (M/DD/YY format) in bottom-left corner
- Temperature in bottom-right corner
- Fade-to-black animation for burn-in prevention
- No media polling - ideal for always-on displays

## Features

- **Configurable Polling** - Reduce controller load by adjusting poll intervals or disabling entirely
- **Device Icon Fallback** - Shows device icon when no cover art is available
- **Live Settings Updates** - Changes in Composer apply without page refresh
- **Burn-in Prevention** - Configurable fade animation in Big Clock mode
- **Debug Logging** - Controllable debug output for troubleshooting

## Notes
- Weather is determined by the Project coordinates in Composer. Make sure this is set to see the weather!
- Big Clock mode is recommended for always-on displays to minimize controller load and prevent screen burn-in

## Roadmap
- [x] Change port number in Composer
- [x] Configure & personalize which widgets are showing
- [x] Device icon fallback when no cover art
- [x] Configurable polling intervals
- [x] Big Clock mode for simple display
- [x] Burn-in prevention
- [ ] Make this a fully inclusive Android app

## Known Issues
- ~~When no media is defined, but the room is active, it will switch to media mode with blank fields.~~
  - Fixed: Now displays device icon as fallback

## Troubleshooting
If the screensaver is not displaying correctly:

<img src="https://raw.githubusercontent.com/13mralex/c4-android-screensaver/main/images/030722171537.png" width=45%></img>

- WebView needs to be updated, which can be downloaded from the Play store or [here](https://www.apkmirror.com/apk/google-inc/android-system-webview/).
- After installing, enable & open Developer Options
- Scroll down and find WebView Implementation and switch to the higher version

## Changelog

### v2.0
- Added configurable HTTP port
- Added Debug Mode with auto-off timer
- Added Show Time/Date/Weather/Media toggles
- Added Background Color and Text Color settings
- Added configurable Media Poll Interval (reduces controller load)
- Added configurable Settings Poll Interval
- Added Display Mode with Big Clock option
- Added Fade Interval for burn-in prevention
- Added device icon fallback when no cover art available
- Added `/settings` endpoint for live settings updates
- Fixed doubled driver names in icon URLs
- Fixed null checks for room media and device info
- Removed all debug comments from Lua code
