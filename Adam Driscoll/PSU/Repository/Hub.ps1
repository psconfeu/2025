Invoke-PSUCommand -Computer 'adamlaptop' -Command "Start-Process" -Parameters @{
    FileName = 'notepad.exe'
}