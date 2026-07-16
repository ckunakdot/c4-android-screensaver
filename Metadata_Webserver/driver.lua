local HTTPPORT = 8089

args = {}
args["title"] = "none"
args["album"] = "none"
args["artist"] = "none"
projectJson = ""

function OnDriverDestroyed()
   if (gDbgTimer ~= 0) then gDbgTimer = C4:KillTimer(gDbgTimer) end
   C4:DestroyServer()
end

function OnPropertyChanged(strProperty)
   local prop = Properties[strProperty]

   if (strProperty == "Debug Mode") then
      if (gDbgTimer > 0) then gDbgTimer = C4:KillTimer(gDbgTimer) end
      g_dbgprint, g_dbglog = (prop:find("Print") ~= nil), (prop:find("Log") ~= nil)
      if (prop == "Off") then
         return
      end
      gDbgTimer = C4:AddTimer(300, "MINUTES")
      dbg("Debug Timer set to 300 Minutes (" .. math.floor((290 / 60) + .5) .. " hours)")
      return
   end

   if (strProperty == "HTTP Port") then
      local newPort = tonumber(prop)
      if (newPort and newPort >= 1024 and newPort <= 65535) then
         if (newPort ~= HTTPPORT) then
            HTTPPORT = newPort
            dbg("HTTP Port changed to: " .. newPort)
            C4:DestroyServer()
            C4:CreateServer(HTTPPORT)
         end
      end
      return
   end

   dbg("Property changed: " .. strProperty .. " = " .. tostring(prop))
end

function dbg(strDebugText)
   if (g_dbgprint) then print(strDebugText) end
   C4:DebugLog("\r\nWeb Event: " .. strDebugText)
end

function ExecuteCommand(strCommand, tParams)
   tParams = tParams or {}
   dbg("ExecuteCommand: " .. strCommand)
   for k,v in pairs(tParams) do dbg("" .. k .. ":" .. v) end
   if (strCommand == "LUA_ACTION") then
      if (tParams.ACTION == "DEFAULT_ACTION") then
         dbg("Default Action")
      end
   end
end

function OnTimerExpired(idTimer)
   if (idTimer == gDbgTimer) then
      dbg("Turning Debug Mode Off (timer expired)")
      C4:UpdateProperty("Debug Mode", "Off")
      OnPropertyChanged("Debug Mode")
      gDbgTimer = C4:KillTimer(gDbgTimer)
   end
   if (idTimer == gInitTimer) then
      MyDriverInit()
      gInitTimer = C4:KillTimer(gInitTimer)
   end
end

function MyDriverInit()
   if (gInitialized ~= nil) then return end
   gInitialized = true
   dbg("MyDriverInit()")
   local savedPort = Properties["HTTP Port"]
   if (savedPort) then
      local portNum = tonumber(savedPort)
      if (portNum and portNum >= 1024 and portNum <= 65535) then
         HTTPPORT = portNum
      end
   end
   C4:CreateServer(HTTPPORT)
   C4:AddVariable("COMMAND", "", "STRING")
   dbg("Initialization Complete. HTTP Port: " .. HTTPPORT)
end

function OnDriverLateInit()
    MyDriverInit()
end

function UnURLEscapeHTTP(strURLEscaped)
   temp = string.gsub(strURLEscaped, " ", "%%20")
   return temp
end

function ParseStatus()
   local _, _, url = string.find(gRecvBuf, "GET /(.*) HTTP")
   url = url or ""
   gCmd = url
   if (string.len(url) > 0) then
      dbg("GET URL: [" .. url .. "]")
      C4:SetVariable("COMMAND", url)
      C4:FireEvent("Command Received")
   else
      dbg("No Command Received.")
      gCmd = "None"
   end
end

function GetWebFile(url,content_type,nHandle)
   dbg("---Getting file: "..url.."---")
   url = C4:GetControllerNetworkAddress().."/c4z/Metadata_Webserver/www/"..url
   dbg("URL: "..url)
   C4:urlGet(url, {}, false,
   function(ticketId, strData, responseCode, tHeaders, strError)
      if (strError == nil) then
         dbg("UrlGet Success")
         headers = GetHeaders(content_type,strData)
         C4:ServerSend(nHandle,  headers .. strData)
         C4:ServerCloseClient(nHandle)
      else
         dbg("C4:urlGet() failed: "..strError)
      end
   end
   )
end

function GetRoomMedia(roomId)
  local args = {}
  local deviceIconUrl = ""
  local roomMediaXml = C4:GetVariable(tonumber(roomId),1031)
  
  if (roomMediaXml == nil or roomMediaXml == "") then
     dbg("No media info for room " .. tostring(roomId))
     return args
  end
  
  local roomMedia = C4:ParseXml(roomMediaXml)
  if (roomMedia) then
     for i,v in pairs(roomMedia.ChildNodes) do
        args[v["Name"]] = v.Value or ""
     end

     local deviceInfoXml = C4:GetDeviceData(tonumber(args["deviceid"]))
     if (deviceInfoXml == nil or deviceInfoXml == "") then
        dbg("No device info for deviceid " .. tostring(args["deviceid"]))
        return args
     end
     
     deviceInfoXml = "<data>"..deviceInfoXml.."</data>"
     local deviceInfo = C4:ParseXml(deviceInfoXml)
     
     if (deviceInfo == nil) then
        dbg("Failed to parse device info XML")
        return args
     end
     
     local ip = C4:GetControllerNetworkAddress()

     for i1,v1 in pairs(deviceInfo.ChildNodes) do
      if(v1.Name == "capabilities") then
        for i2,v2 in pairs(deviceInfo.ChildNodes[i1].ChildNodes) do
           if (v2.Name == "navigator_display_option") then
             for i3,v3 in pairs(deviceInfo.ChildNodes[i1].ChildNodes[i2].ChildNodes) do
              if (v3.Name == "display_icons") then
                deviceIconUrl = deviceInfo.ChildNodes[i1].ChildNodes[i2].ChildNodes[i3].ChildNodes[1].Value
              end
             end
           end
        end
      end
     end

     args["devicename"] = C4:ListGetDeviceName(args["deviceid"]) or ""

     local deviceImgUrl = ""
     local deviceImgFallback = ""
     
     dbg("Raw deviceIconUrl: " .. tostring(deviceIconUrl))
     
     if (deviceIconUrl and deviceIconUrl ~= "") then
        local prefix, path = deviceIconUrl:match("(.+)://(.+)")
        dbg("Icon prefix: " .. tostring(prefix) .. ", path: " .. tostring(path))
        
        if (prefix == "driver" and path) then
           local driverName, remainingPath = path:match("([^/]+)/(.+)")
           if (driverName and remainingPath) then
              local halfLen = math.floor(#driverName / 2)
              local firstHalf = driverName:sub(1, halfLen)
              local secondHalf = driverName:sub(halfLen + 2)
              if (firstHalf == secondHalf) then
                 driverName = firstHalf
              end
              local iconDir = remainingPath:match("(.+)/[^/]+$") or ""
              deviceImgUrl = "http://" .. ip .. "/c4z/" .. driverName .. "/www/" .. iconDir .. "/experience_1024.png"
              deviceImgFallback = "http://" .. ip .. "/c4z/" .. driverName .. "/www/" .. remainingPath
              dbg("Converted device icon URL: " .. deviceImgUrl)
           end
        elseif (prefix == "controller" and path) then
           deviceImgUrl = "http://" .. ip .. "/" .. path
           deviceImgFallback = deviceImgUrl
        elseif (prefix and path) then
           deviceImgUrl = deviceIconUrl
           deviceImgFallback = deviceIconUrl
        end
     end
     
     args["deviceIcon"] = deviceImgUrl
     args["deviceIconFallback"] = deviceImgFallback

     if (args["img"] == nil or args["img"] == "") then
        args["img"] = deviceImgUrl
        args["imgFallback"] = deviceImgFallback
        dbg("No cover art, using device icon: " .. tostring(deviceImgUrl))
     else
        local imgUrl = C4:Base64Decode(args["img"])
        if (imgUrl and imgUrl ~= "") then
           local imgPrefix,imgPath = imgUrl:match("(.+)://(.+)")
           if (imgPrefix == "controller") then
              imgUrl = "http://"..ip.."/"..imgPath
           end
           args["img"] = imgUrl
        else
           args["img"] = deviceImgUrl
           args["imgFallback"] = deviceImgFallback
        end
     end
  end
  return args
end

function GetHeaders(ContentType,msg)
   res = "HTTP/1.1 200 OK\r\nContent-Length: " .. msg:len() .. "\r\nContent-Type: "..ContentType.."\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
   return res
end

function GetSettingsJson()
   local timeFormat = Properties["Time Format"] or "12 Hour"
   local showTime = Properties["Show Time"] or "Yes"
   local showDate = Properties["Show Date"] or "Yes"
   local showWeather = Properties["Show Weather"] or "Yes"
   local showMedia = Properties["Show Media"] or "Yes"
   local displayMode = Properties["Display Mode"] or "Normal"
   local fadeInterval = Properties["Fade Interval"] or "1 Minute"
   local backgroundColor = Properties["Background Color"] or "#000000"
   local textColor = Properties["Text Color"] or "#FFFFFF"
   local mediaPollInterval = Properties["Media Poll Interval"] or "3 Seconds"
   local settingsPollInterval = Properties["Settings Poll Interval"] or "60 Seconds"
   
   local mediaPollMs = 3000
   if (mediaPollInterval == "1 Second") then mediaPollMs = 1000
   elseif (mediaPollInterval == "2 Seconds") then mediaPollMs = 2000
   elseif (mediaPollInterval == "3 Seconds") then mediaPollMs = 3000
   elseif (mediaPollInterval == "5 Seconds") then mediaPollMs = 5000
   elseif (mediaPollInterval == "10 Seconds") then mediaPollMs = 10000
   end
   
   local settingsPollMs = 60000
   if (settingsPollInterval == "5 Seconds") then settingsPollMs = 5000
   elseif (settingsPollInterval == "10 Seconds") then settingsPollMs = 10000
   elseif (settingsPollInterval == "30 Seconds") then settingsPollMs = 30000
   elseif (settingsPollInterval == "60 Seconds") then settingsPollMs = 60000
   elseif (settingsPollInterval == "5 Minutes") then settingsPollMs = 300000
   end
   
   local fadeIntervalSec = 60
   if (fadeInterval == "30 Seconds") then fadeIntervalSec = 30
   elseif (fadeInterval == "1 Minute") then fadeIntervalSec = 60
   elseif (fadeInterval == "2 Minutes") then fadeIntervalSec = 120
   elseif (fadeInterval == "5 Minutes") then fadeIntervalSec = 300
   elseif (fadeInterval == "10 Minutes") then fadeIntervalSec = 600
   end
   
   local settingsTable = {
      timeFormat = timeFormat,
      showTime = (showTime == "Yes"),
      showDate = (showDate == "Yes"),
      showWeather = (showWeather == "Yes"),
      showMedia = (showMedia == "Yes"),
      displayMode = displayMode,
      fadeInterval = fadeIntervalSec,
      backgroundColor = backgroundColor,
      textColor = textColor,
      mediaPollInterval = mediaPollMs,
      settingsPollInterval = settingsPollMs
   }
   
   dbg("GetSettingsJson: " .. C4:JsonEncode(settingsTable))
   return C4:JsonEncode(settingsTable)
end

function OnServerConnectionStatusChanged(nHandle, nPort, strStatus)
end

function OnServerDataIn(nHandle, strData)
   msg = ""
   headers = ""
   args2 = {}
   gRecvBuf = strData
   local ret, err = pcall(ParseStatus)
   if (ret ~= true) then
      local e = "Error Parsing return status: " .. err
      dbg(e)
      C4:ErrorLog(e)
   end
   gRecvBuf = ""

   urlArgs = {}

   for i in string.gmatch(gCmd, "[^/]+") do
      urlArgs[#urlArgs+1] = i
   end
   dbg("Processing request...")
   if tonumber(gCmd) then
      dbg("Room ID request: " .. gCmd)
      roomId = gCmd
      res = GetRoomMedia(roomId)
      msg = GetMainHtml(res)
      GetWebFile("html/main.html","html",nHandle)
   elseif (urlArgs[2] == "json") then
      roomId = urlArgs[1]
      res = GetRoomMedia(roomId)
      msg = C4:JsonEncode(res)
      headers = GetHeaders("text/json",msg)
      C4:ServerSend(nHandle,  headers .. msg)
      C4:ServerCloseClient(nHandle)
   elseif (gCmd == "project") then
      msg = projectJson
      headers = GetHeaders("text/json",msg)
      C4:ServerSend(nHandle,  headers .. msg)
      C4:ServerCloseClient(nHandle)
   elseif (gCmd == "settings") then
      msg = GetSettingsJson()
      headers = GetHeaders("application/json",msg)
      C4:ServerSend(nHandle,  headers .. msg)
      C4:ServerCloseClient(nHandle)
   elseif (urlArgs[1] == "png") then
      GetWebFile(gCmd,"image/png",nHandle)
   else
      GetWebFile(gCmd,"text/"..urlArgs[1],nHandle)
   end
end

function GetMainHtml(args1)
   if (args1["title"] == nil) then
      args1["title"] = ""
   elseif (args1["artist"] == nil) then
      args1["artist"] = ""
   elseif (args1["album"] == nil) then
      args1["album"] = ""
   end

   mainHtml = [[
   <!doctype html>
   <html>
   <head>
   <meta charset="UTF-8">
   <title>C4-Android-Screensaver</title>
   <script type="text/javascript" src="metadata.js"></script>
   <link href="style.css" rel="stylesheet" type="text/css">
   <link rel="preconnect" href="https://fonts.googleapis.com">
   <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
   <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@100;300&display=swap" rel="stylesheet">
   </head>
   <body onLoad="populateMetadata()">
   <div id="main-container">
   <div id="date-time-temp-container">
   <div id="time">
   <span class="text" id="clock"></span>
   <span class="text" id="ampm"></span>
   </div>
   <div id="date">
   <span class="text" id="dayofweek"></span>
   <span class="text" id="day"></span>
   <span class="text" id="month"></span>
   </div>
   <div id="temp">
   <span class="text" id="temp-num"></span>
   <span class="text" id="scale"></span>
   </div>
   </div>
   <div id="metadata-container">
   <div id="art-container">
   <img id="art" src="" alt=""/>
   </div>
   <div id="metadata-text-container">
   <span id="album" class="text"></span>
   <span id="artist" class="text"></span>
   <span id="title" class="text"></span>
   </div>
   </div>
   </div>
   </body>
   </html>
   ]]
   return mainHtml
end

project = {}

function OnDriverLateInit()
dbg("Driver late init...")

function get(data,name)
return data:match("<"..name..">(.-)</"..name..">")
end

projectInfo = C4:GetProjectItems()
projectInfo = get(projectInfo,"itemdata")
projectInfo = "<itemdata>"..projectInfo.."</itemdata>"
projectInfo = C4:ParseXml(projectInfo)

project = {}

for i,v in pairs(projectInfo["ChildNodes"]) do
project[v["Name"]] = v.Value
end

projectJson = C4:JsonEncode(project)
end

gRecvBuf = ""
gDbgTimer = 0
gCmd = ""

OnPropertyChanged("Debug Mode")
gInitTimer = C4:AddTimer(5, "SECONDS")
