#SingleInstance, Force

httpRequest := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
#Persistent
brightness := 100 ; set initial brightness to 100%
lastBrightnessSent := -1 ; set last brightness sent to an impossible value
increment := 10 ; set the increment to 10%
hue_ip := "192.168.0.137" ; set the IP address of your Hue bridge
hue_username := "AbGTyPNFZhAuATZex0GKwJal8KoR9JHIU4htnQWj" ; set your Hue API key
sendDelay := 100 ; set delay time between requests (in milliseconds)

; Define the context for the hotkeys
#If GetKeyState("F13", "P")

SC12E::
    brightness := Max(brightness - increment, 0) ; decrease brightness by the increment amount, but don't go below 0%
    ControlHueLight(brightness)
return

SC130::
    brightness := Min(brightness + increment, 100) ; increase brightness by the increment amount, but don't go above 100%
    ControlHueLight(brightness)
return

; End the context definition
#If

ControlHueLight(brightness) {
    global hue_ip
    global hue_username
    global httpRequest
    global lastBrightnessSent
    global sendDelay
    
    ; convert the brightness level to a scale of 0-254 (the range used by the Hue API)
    hue_brightness := Round((brightness / 100) * 254)
    
    ; check if the brightness level has changed since the last request was sent
    if (hue_brightness != lastBrightnessSent) {
        FileAppend, Brightness increased to %brightness%`n, log.txt
        
        ; construct the URL to set the brightness of your Hue light(s)
        url := "http://" . hue_ip . "/api/" . hue_username . "/groups/0/action"
        
        ; construct the JSON payload to set the brightness of your Hue light(s)
        payload = {"bri" : %hue_brightness%}
        
        ; send an HTTP PUT request to set the brightness of your Hue light(s)
        httpRequest.Open("PUT", url, 0)
        httpRequest.Send(payload)
        
        ; set the last brightness sent to the current brightness
        lastBrightnessSent := hue_brightness
        
        ; wait for the specified delay time before allowing the next request to be sent
        Sleep sendDelay
    }
}