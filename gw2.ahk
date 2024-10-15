#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

; 以管理员权限运行脚本
if not A_IsAdmin
{
    try
    {
        Run '*RunAs "' A_ScriptFullPath '"'
    }
    ExitApp
}

; 全局变量
global isRunning := false
global MainGui, speedX, speedY, duration, interval, zoomDirection, enableMoveX, enableMoveY, enableZoom, startHotkey, stopHotkey, showGuiHotkey, statusText, zoomTimes, isTopmost := true
global speedXSlider, speedYSlider, durationSlider, intervalSlider, zoomTimesSlider
global tooltipTimer := 0
global holdKey  ; 新增全局变量
global currentLanguage := "中文"
global languageDropdown

; 创建主窗口
MainGui := Gui("+Resize")
MainGui.Title := "GW2相机移动控制"
MainGui.Opt("+AlwaysOnTop")
MainGui.BackColor := "F0F0F0"  ; 设置背景颜色

; 在创建主窗口后,添加版权信息
copyrightText := MainGui.Add("Text", "x10 y740 w320 c0000FF", "© 小白牙 - 点击访问B站主页")
copyrightText.SetFont("s9 underline", "Arial")
copyrightText.OnEvent("Click", (*) => Run("https://space.bilibili.com/449932"))

; 修改主窗口标题,包含��权信息
MainGui.Title := "GW2相机移动控制 © 小白牙"

; 添加一个函数来创建分组
CreateGroup(title, x, y, w, h)
{
    group := MainGui.Add("GroupBox", "x" . x . " y" . y . " w" . w . " h" . h . " v" . title, title)
    group.SetFont("s10 bold", "Arial")
    return group
}

; 创建分组
movementGroup := CreateGroup("MovementGroup", 10, 10, 320, 220)
zoomGroup := CreateGroup("ZoomGroup", 10, 240, 320, 100)
controlGroup := CreateGroup("ControlGroup", 10, 350, 320, 170)
presetGroup := CreateGroup("PresetGroup", 10, 530, 320, 170)

; 修改 AddControlWithInfoButton 函数
AddControlWithInfoButton(text, tooltip, x, y, w := 100, controlWidth := 50, textName := "")
{
    if (textName != "")
        MainGui.Add("Text", "x" . x . " y" . y . " w" . w . " v" . textName, text)
    else
        MainGui.Add("Text", "x" . x . " y" . y . " w" . w, text)
    control := MainGui.Add("Edit", "x" . (x+w+5) . " y" . y . " w" . controlWidth)
    infoButton := MainGui.Add("Button", "x" . (x+w+controlWidth+10) . " y" . y . " w20 h20", "i")
    infoButton.SetFont("s8 bold", "Arial")
    infoButton.OnEvent("Click", (*) => ShowTooltip(tooltip))
    return control
}

; 修改 AddSliderWithInfoButton 函数,删除信息按钮并增加滑条长度
AddSlider(text, x, y, w := 100, sliderWidth := 180, sliderRange := "Range1-100")
{
    MainGui.Add("Text", "x" . x . " y" . y . " w" . w, text)
    slider := MainGui.Add("Slider", "x" . (x+w+5) . " y" . y . " w" . sliderWidth . " " . sliderRange)
    return slider
}

; 修改 ShowTooltip 函数
ShowTooltip(tooltipText)
{
    if (Type(tooltipText) == "Object") {
        ToolTip(currentLanguage == "中文" ? tooltipText.chinese : tooltipText.english)
    } else {
        ToolTip(tooltipText)
    }
    SetTimer () => ToolTip(), -6000  ; 6秒后自动隐藏tooltip
}

; X轴速度
speedX := AddControlWithInfoButton("X轴速度:", {
    chinese: "设置相机在左右方向的移动速度，正数为往右，负数为往左，允许小数点（但不能在1到-1之间）。`n为了更平滑的移动，建议将游戏内的旋转速度降到最低。",
    english: "Set the camera movement speed in the left-right direction. Positive for right, negative for left. Decimals allowed.`nFor smoother movement, it's recommended to set the in-game rotation speed to the lowest."
}, 20, 35, 90, 40, "TextSpeedX")
speedX.Value := "10"
speedXSlider := AddSlider("", 180, 35, 10, 130, "Range-100-100")
speedXSlider.Value := 10
speedXSlider.OnEvent("Change", SyncSpeedX)

; Y轴速度
speedY := AddControlWithInfoButton("Y轴速度:", {
    chinese: "设置相机在上下方向的移动速度，正数为往下，负数为往上，允许小数点。（但不能在1到-1之间）`n为了更平滑的移动，建议将游戏内的旋转速度降到最低。",
    english: "Set the camera movement speed in the up-down direction. Positive for down, negative for up. Decimals allowed.`nFor smoother movement, it's recommended to set the in-game rotation speed to the lowest."
}, 20, 65, 90, 40, "TextSpeedY")
speedY.Value := "1"
speedYSlider := AddSlider("", 180, 65, 10, 130, "Range-100-100")
speedYSlider.Value := 1
speedYSlider.OnEvent("Change", SyncSpeedY)

; 持续时间
duration := AddControlWithInfoButton("持续时间(ms):", {
    chinese: "设置相机移动的总持续时间`n（因为电脑反应问题，间隔时间小于10ms的话，该选项可能比实际时间要长）",
    english: "Set the total duration of camera movement.`n(Due to computer response issues, if the interval is less than 10ms, this option may be longer than the actual time)"
}, 20, 95, 90, 40, "TextDuration")
duration.Value := "2000"
durationSlider := AddSlider("", 180, 95, 10, 130, "Range100-10000")
durationSlider.Value := 2000
durationSlider.OnEvent("Change", SyncDuration)

; 平滑间隔
interval := AddControlWithInfoButton("平滑间隔(ms):", {
    chinese: "设置每次平滑的��间间隔，建议10ms以上`n此数值会影响到X和Y轴的速度，间隔时间越大，X和Y轴的速度越慢",
    english: "Set the time interval for each smooth movement. Recommended to be above 10ms.`nThis value affects the speed of X and Y axes. The larger the interval, the slower the X and Y axis speeds."
}, 20, 125, 90, 40, "TextInterval")
interval.Value := "10"
intervalSlider := AddSlider("", 180, 125, 10, 130, "Range1-100")
intervalSlider.Value := 5
intervalSlider.OnEvent("Change", SyncInterval)

; 修改 AddCheckboxWithInfoButton 函数
AddCheckboxWithInfoButton(text, tooltip, x, y, w := 150)
{
    checkbox := MainGui.Add("Checkbox", "x" . x . " y" . y . " w" . w . " Checked", text)
    infoButton := MainGui.Add("Button", "x" . (x+w+5) . " y" . y . " w20 h20", "i")
    infoButton.SetFont("s8 bold", "Arial")
    infoButton.OnEvent("Click", (*) => ShowTooltip(tooltip))
    return checkbox
}

; 调整复选框的位置和宽度
enableMoveX := AddCheckboxWithInfoButton("启用X轴移动", {
    chinese: "开启或关闭相机X轴移动功能",
    english: "Enable or disable camera X-axis movement"
}, 20, 160, 110)
enableMoveY := AddCheckboxWithInfoButton("启用Y轴移动", {
    chinese: "开启或关闭相机Y轴移动功能",
    english: "Enable or disable camera Y-axis movement"
}, 170, 160, 110)
enableZoom := AddCheckboxWithInfoButton("启用缩放", {
    chinese: "因为激战2的限制，哪怕把缩放灵敏度调到最低，依然还是有很明显的不平滑`n所以使用此选项时，建议X轴速度10以上，并且持续时间在2秒以内，会有较好的效果",
    english: "Due to GW2 limitations, even with zoom sensitivity set to minimum, it's still noticeably unsmooth.`nWhen using this option, it's recommended to set X-axis speed above 10 and duration within 2 seconds for better results."
}, 20, 190, 110)

; 视角缩放方向
MainGui.Add("Text", "x20 y265 w90 vTextZoomDirection", "视角缩放方向:")
zoomDirection := MainGui.Add("DropDownList", "x115 y265 w90", ["拉近视角", "拉远视角"])
zoomDirection.Choose(1)
infoButton := MainGui.Add("Button", "x210 y265 w20 h20", "i")
infoButton.SetFont("s8 bold", "Arial")
infoButton.OnEvent("Click", (*) => ShowTooltip({
    chinese: "选择相机视角的移动方向",
    english: "Select the direction of camera view movement"
}))

; 缩放次数
zoomTimes := AddControlWithInfoButton("缩放次数:", {
    chinese: "游戏内缩放灵敏度必须调到最低`n38次是实测从最远拉到最近的最大次数。",
    english: "In-game zoom sensitivity must be set to minimum.`n38 times is the maximum number tested to zoom from farthest to nearest."
}, 20, 295, 90, 40, "TextZoomTimes")
zoomTimes.Value := "38"
zoomTimesSlider := AddSlider("", 180, 295, 10, 130, "Range1-38")
zoomTimesSlider.Value := 38
zoomTimesSlider.OnEvent("Change", SyncZoomTimes)

; 添加"按住自定义按键"的输入框和提示
holdKey := AddControlWithInfoButton("按住自定义按键:", {
    chinese: "设置在XY轴运动期间要按住的按键,默认为W",
    english: "Set the key to hold during XY axis movement, default is W"
}, 20, 375, 90, 40, "TextHoldKey")
holdKey.Value := "w"

; 添加"自定义按键"的复选框
enableHoldKey := AddCheckboxWithInfoButton("启用自定义按键", {
    chinese: "开启或关闭自定义按键功能",
    english: "Enable or disable custom key function"
}, 20, 405, 130)

MainGui.Add("Text", "x20 y435 w90 vTextStartHotkey", "启动热键:")
startHotkey := MainGui.Add("Hotkey", "x115 y435 w90 vStartHotkey", "F1")
MainGui.Add("Text", "x20 y465 w90 vTextStopHotkey", "终止热键:")
stopHotkey := MainGui.Add("Hotkey", "x115 y465 w90 vStopHotkey", "F2")
MainGui.Add("Text", "x20 y495 w90 vTextShowGuiHotkey", "显示窗口热键:")
showGuiHotkey := MainGui.Add("Hotkey", "x115 y495 w90 vShowGuiHotkey", "F3")

applyButton := MainGui.Add("Button", "x220 y435 w100 h30", "应用热键设置")
applyButton.OnEvent("Click", ApplyHotkeys)

toggleTopmostButton := MainGui.Add("Button", "x220 y475 w100 h30", "当前：窗口置顶")
toggleTopmostButton.OnEvent("Click", ToggleTopmost)

statusText := MainGui.Add("Text", "x20 y710 w200 h30 vStatus", "状态: 已停止")
statusText.SetFont("s10 bold", "Arial")

; 定义预设镜头设置
presets := [
    {name: "人物走路展示", nameEn: "Character Walking Demo", speedX: 10, speedY: 1, duration: 5000, interval: 10, zoom: true, zoomDirection: 1, zoomTimes: 20, holdKey: "w"},
    {name: "人物1技能攻击展示", nameEn: "Character Skill 1 Attack Demo", speedX: 15, speedY: -1, duration: 4000, interval: 10, zoom: true, zoomDirection: 1, zoomTimes: 25, holdKey: "1"},
    {name: "塞尔达式拉远", nameEn: "Zelda-style Zoom Out", speedX: 1, speedY: -0.2, duration: 3000, interval: 10, zoom: true, zoomDirection: 2, zoomTimes: 38, holdKey: "w"},
    {name: "远景大建筑右平移视角", nameEn: "Panoramic Building Right Pan", speedX: -1, speedY: 0, duration: 6000, interval: 30, zoom: false, zoomDirection: 2, zoomTimes: 15, holdKey: "d"},
    {name: "角色特写聚焦", nameEn: "Character Close-up Focus", speedX: 10, speedY: -1, duration: 3500, interval: 10, zoom: true, zoomDirection: 1, zoomTimes: 38, holdKey: ""}
]

; 添加预设按钮
for index, preset in presets {
    presetButton := MainGui.Add("Button", "x20 y" . (560 + (index-1)*30) . " w300 h25", preset.name)
    presetButton.OnEvent("Click", ApplyPreset.Bind(preset))
    presetButton.Name := "Preset" . index
}

; 修改 ApplyPreset 函数
ApplyPreset(preset, *)
{
    speedX.Value := preset.speedX
    speedXSlider.Value := preset.speedX
    speedY.Value := preset.speedY
    speedYSlider.Value := preset.speedY
    duration.Value := preset.duration
    durationSlider.Value := preset.duration
    interval.Value := preset.interval
    intervalSlider.Value := preset.interval
    enableMoveX.Value := (preset.speedX != 0)
    enableMoveY.Value := (preset.speedY != 0)
    enableZoom.Value := preset.zoom
    if (preset.zoom) {
        ; 修改这里，使用索引不是文本来选择
        zoomDirection.Choose(preset.zoomDirection == "拉近视角" ? 1 : 2)
        zoomTimes.Value := preset.zoomTimes
        zoomTimesSlider.Value := preset.zoomTimes
    }
    holdKey.Value := preset.holdKey
    enableHoldKey.Value := (preset.holdKey != "")
    MsgBox((currentLanguage == "中文") ? "已应用预设: " . preset.name : "Preset applied: " . preset.nameEn, (currentLanguage == "中文") ? "预设应用成功" : "Preset Applied Successfully", "0x40")
}

; 在创建主窗口后添加语言选择下拉列表
MainGui.Add("Text", "x170 y713 w60", "Language:")
languageDropdown := MainGui.Add("DropDownList", "x230 y710 w90", ["中文", "English"])
languageDropdown.Choose(1)
languageDropdown.OnEvent("Change", ChangeLanguage)

; 添加语言切换函数
ChangeLanguage(*)
{
    global currentLanguage
    newLanguage := languageDropdown.Text
    if (newLanguage != currentLanguage) {
        currentLanguage := newLanguage
        UpdateUILanguage()
    }
}

; 添加更新UI语言的函数
UpdateUILanguage()
{
    if (currentLanguage == "中文") {
        MainGui.Title := "GW2相机移动控制 © 小白牙"
        copyrightText.Text := "© 小白牙 - 点击访问B站主页"
        MainGui["TextSpeedX"].Text := "X轴速度:"
        MainGui["TextSpeedY"].Text := "Y轴速度:"
        MainGui["TextDuration"].Text := "持续时间(ms):"
        MainGui["TextInterval"].Text := "平滑间隔(ms):"
        MainGui["TextZoomDirection"].Text := "视角缩放方向:"
        zoomDirection.Delete()
        zoomDirection.Add(["拉近视角", "拉远视角"])
        zoomDirection.Choose(1)
        MainGui["TextZoomTimes"].Text := "缩放次数:"
        enableMoveX.Text := "启用X轴移动"
        enableMoveY.Text := "启用Y轴移动"
        enableZoom.Text := "启用缩放"
        enableHoldKey.Text := "启用自定义按键"
        MainGui["TextHoldKey"].Text := "按住自定义按键:"
        MainGui["TextStartHotkey"].Text := "启动热键:"
        MainGui["TextStopHotkey"].Text := "终止热键:"
        MainGui["TextShowGuiHotkey"].Text := "显示窗口热键:"
        applyButton.Text := "应用热键设置"
        toggleTopmostButton.Text := isTopmost ? "当前：窗口置顶" : "当前：不置顶"
        statusText.Text := isRunning ? "状态: 运行中" : "状态: 已停止"
        MainGui["MovementGroup"].Text := "移动设置"
        MainGui["ZoomGroup"].Text := "缩放设置"
        MainGui["ControlGroup"].Text := "控制设置"
        MainGui["PresetGroup"].Text := "预设镜头"
        MainGui["TextLanguage"].Text := "Language:"
    } else {
        MainGui.Title := "GW2 CMC © XiaoBaiYa"
        copyrightText.Text := "© XiaoBaiYa - Click to visit Bilibili homepage"
        MainGui["TextSpeedX"].Text := "X-axis Speed:"
        MainGui["TextSpeedY"].Text := "Y-axis Speed:"
        MainGui["TextDuration"].Text := "Duration (ms):"
        MainGui["TextInterval"].Text := "Smooth Interval (ms):"
        MainGui["TextZoomDirection"].Text := "Zoom Direction:"
        zoomDirection.Delete()
        zoomDirection.Add(["Zoom In", "Zoom Out"])
        zoomDirection.Choose(1)
        MainGui["TextZoomTimes"].Text := "Zoom Times:"
        enableMoveX.Text := "Enable X Move"
        enableMoveY.Text := "Enable Y Move"
        enableZoom.Text := "Enable Zoom"
        enableHoldKey.Text := "Enable Custom Key"
        MainGui["TextHoldKey"].Text := "Hold Key:"
        MainGui["TextStartHotkey"].Text := "Start Hotkey:"
        MainGui["TextStopHotkey"].Text := "Stop Hotkey:"
        MainGui["TextShowGuiHotkey"].Text := "Show Window Hotkey:"
        applyButton.Text := "Apply Hotkey Settings"
        toggleTopmostButton.Text := isTopmost ? "Current: Always on Top" : "Current: Not on Top"
        statusText.Text := isRunning ? "Status: Running" : "Status: Stopped"
        MainGui["MovementGroup"].Text := "Movement Settings"
        MainGui["ZoomGroup"].Text := "Zoom Settings"
        MainGui["ControlGroup"].Text := "Control Settings"
        MainGui["PresetGroup"].Text := "Preset Shots"
        MainGui["TextLanguage"].Text := "语言:"
    }
    
    ; 更新预设按钮文本
    for index, preset in presets {
        presetButton := MainGui["Preset" . index]
        presetButton.Text := (currentLanguage == "中文") ? preset.name : preset.nameEn
    }
}

; 确保在创建主窗口时添加TextLanguage控件
MainGui.Add("Text", "x170 y713 w60 vTextLanguage", "语言:")

; 在显示GUI之前调用UpdateUILanguage
UpdateUILanguage()
MainGui.Show("w340 h770")  ; 调整主窗口大小以适应新添加的版权信息

; 同步函数
SyncSpeedX(*)
{
    speedX.Value := speedXSlider.Value
}

SyncSpeedY(*)
{
    speedY.Value := speedYSlider.Value
}

SyncDuration(*)
{
    duration.Value := durationSlider.Value
}

SyncInterval(*)
{
    interval.Value := intervalSlider.Value
}

SyncZoomTimes(*)
{
    zoomTimes.Value := zoomTimesSlider.Value
}

ApplyHotkeys(*)
{
    global startHotkeyFunc, stopHotkeyFunc, showGuiHotkeyFunc
    
    ; 移除旧的热键（如果存在）
    try Hotkey(startHotkeyFunc, "Off")
    try Hotkey(stopHotkeyFunc, "Off")
    try Hotkey(showGuiHotkeyFunc, "Off")
    
    ; 设置新的热键
    startHotkeyFunc := startHotkey.Value
    stopHotkeyFunc := stopHotkey.Value
    showGuiHotkeyFunc := showGuiHotkey.Value
    
    if (startHotkeyFunc != "") {
        Hotkey(startHotkeyFunc, StartScript, "On")
    }
    
    if (stopHotkeyFunc != "") {
        Hotkey(stopHotkeyFunc, StopScript, "On")
    }
    
    if (showGuiHotkeyFunc != "") {
        Hotkey(showGuiHotkeyFunc, ShowMainGui, "On")
    }
    
    msgBoxText := currentLanguage == "中文" 
        ? "热键设置已应用。`n启动热键: " . startHotkeyFunc . "`n终止热键: " . stopHotkeyFunc . "`n显示窗口热键: " . showGuiHotkeyFunc
        : "Hotkey settings applied.`nStart hotkey: " . startHotkeyFunc . "`nStop hotkey: " . stopHotkeyFunc . "`nShow window hotkey: " . showGuiHotkeyFunc
    MsgBox(msgBoxText, currentLanguage == "中文" ? "设置成功" : "Settings Applied", "4096 T3")
}

StartScript(*)
{
    global isRunning
    if (isRunning) {
        return
    }
    isRunning := true
    statusText.Value := currentLanguage == "中文" ? "状态: 运行中" : "Status: Running"
    
    ; 获取GUI中的值
    speed_x := Integer(speedX.Value)
    speed_y := Integer(speedY.Value)
    script_duration := Integer(duration.Value)
    script_interval := Integer(interval.Value)
    zoom_direction := (zoomDirection.Text == "拉近视角") ? 1 : -1
    zoom_times := Integer(zoomTimes.Value)
    enable_move_x := enableMoveX.Value
    enable_move_y := enableMoveY.Value
    enable_zoom := enableZoom.Value
    enable_hold_key := enableHoldKey.Value
    hold_key := holdKey.Value
    
    ; 计算总移动次数和缩放间隔
    moves := script_duration // script_interval
    zoom_interval := moves // zoom_times
    
    ; 设置起始位置并按下鼠标左键
    MouseGetPos(&start_x, &start_y)
    SendInput("{LButton Down}")
    
    ; 按下设定的按键（如果启用）
    if (enable_hold_key and hold_key != "") {
        SendInput("{" . hold_key . " down}")
    }
    
    zoom_count := 0
    Loop moves {
        if (!isRunning) {
            break
        }
        
        ; 执行X轴移动
        if (enable_move_x) {
            DllCall("mouse_event", "UInt", 0x0001, "Int", speed_x, "Int", 0, "UInt", 0, "Ptr", 0)
        }
        
        ; 执行Y轴移动
        if (enable_move_y) {
            DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", speed_y, "UInt", 0, "Ptr", 0)
        }
        
        ; 执行缩放
        if (enable_zoom and Mod(A_Index, zoom_interval) < 1) {
            if (zoom_direction > 0) {
                SendInput("{WheelUp}")
            } else {
                SendInput("{WheelDown}")
            }
            zoom_count++
        }
        
        Sleep(script_interval)
    }
    
    ; 确保完成所有缩放操作
    while (enable_zoom and zoom_count < zoom_times and isRunning) {
        if (zoom_direction > 0) {
            SendInput("{WheelUp}")
        } else {
            SendInput("{WheelDown}")
        }
        zoom_count++
        Sleep(script_interval)
    }
    
    ; 释放鼠标左键
    SendInput("{LButton Up}")
    
    ; 释放设定的按键（如果启用）
    if (enable_hold_key and hold_key != "") {
        SendInput("{" . hold_key . " up}")
    }
    
    ; 恢复鼠标初始位置
    DllCall("SetCursorPos", "int", start_x, "int", start_y)
    
    isRunning := false
    statusText.Value := currentLanguage == "中文" ? "状态: 已停止" : "Status: Stopped"
}

StopScript(*)
{
    global isRunning
    isRunning := false
    statusText.Value := currentLanguage == "中文" ? "状态: 已停止" : "Status: Stopped"
    SendInput("{LButton Up}")  ; 确保鼠标左键被释放
}

ShowMainGui(*)
{
    MainGui.Show()
}

ToggleTopmost(*)
{
    global isTopmost
    isTopmost := !isTopmost
    if (isTopmost) {
        MainGui.Opt("+AlwaysOnTop")
        toggleTopmostButton.Text := currentLanguage == "中文" ? "当前：窗口置顶" : "Current: Always on Top"
    } else {
        MainGui.Opt("-AlwaysOnTop")
        toggleTopmostButton.Text := currentLanguage == "中文" ? "当前：不置顶" : "Current: Not on Top"
    }
}

; 确保脚本退出时释放鼠标按键
ExitFunc(*)
{
    SendInput("{LButton Up}")
}

OnExit(ExitFunc)

; 在脚本开始时立即应用默认热键
ApplyDefaultHotkeys()

ApplyDefaultHotkeys()
{
    global startHotkeyFunc, stopHotkeyFunc, showGuiHotkeyFunc
    
    startHotkeyFunc := "F1"
    stopHotkeyFunc := "F2"
    showGuiHotkeyFunc := "F3"
    
    Hotkey(startHotkeyFunc, StartScript, "On")
    Hotkey(stopHotkeyFunc, StopScript, "On")
    Hotkey(showGuiHotkeyFunc, ShowMainGui, "On")
}