# GW2 Camera Movement Control Tool

## Introduction
The GW2 Camera Movement Control Tool is an advanced camera control script designed for Guild Wars 2 players. It allows players to precisely control in-game camera movements, creating smooth and professional-looking gameplay footage and videos.

## Key Features
- X-axis and Y-axis camera movement control
- Adjustable movement speed and duration
- Camera zoom functionality
- Custom key support
- Preset camera settings
- Multi-language support (Chinese and English)

## Usage Instructions
1. Ensure AutoHotkey v2.0 is installed on your computer.
2. Download and run the `gw2.ahk` script as administrator.
3. Use the graphical interface to adjust camera movement settings.
4. Use the preset hotkeys (default F1 to start, F2 to stop, F3 to show/hide control window).

## Detailed Settings Explanation
- **X-axis and Y-axis Speed**: Set camera movement speed. Positive for right/down, negative for left/up. Cannot be between 1 and -1.
- **Duration**: Set the total duration of camera movement (in milliseconds).
- **Smooth Interval**: Time interval between each movement. Recommended to be above 10ms. Affects movement smoothness.
- **Zoom Times**: Set the number of zoom steps, maximum 38 (from farthest to nearest).
- **Custom Key**: Option to hold a specific key (e.g., W) during camera movement.

## Important Notes
- Using third-party tools carries risks. Use this tool at your own discretion. The author bears no responsibility for any consequences or liabilities arising from the use of this tool.
- It's recommended to set the in-game camera rotation speed to the lowest for the smoothest movement.
- When using the zoom function, set the in-game zoom sensitivity to the lowest.
- X-axis and Y-axis speeds cannot be set between 1 and -1, as this may prevent camera movement.
- When the smooth interval is set very low (less than 10ms), the actual movement time may be longer than the set duration.
- For zoom functionality, it's recommended to set X-axis speed above 10 and duration within 2 seconds for better results.
- This tool requires administrator privileges to run properly.
- Use the preset function to quickly apply common camera movement settings.

## Troubleshooting
- If the script fails to run, ensure you're running it with administrator privileges.
- If camera movement is not smooth, try increasing the smooth interval or lowering the in-game camera sensitivity.
- If zoom effects are not ideal, ensure the in-game zoom sensitivity is set to the lowest.

## Contributions
Bug reports and improvement suggestions are welcome. If you'd like to contribute to the project, please submit a Pull Request.

## Author
XiaoBaiYa - [Bilibili Homepage](https://space.bilibili.com/449932)

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
