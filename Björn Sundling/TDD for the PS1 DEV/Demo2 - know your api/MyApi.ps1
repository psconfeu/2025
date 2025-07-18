# remember to start pode 😉
# ..\setup\startAPIServer.ps1


Invoke-RestMethod http://localhost:666/api


Invoke-RestMethod http://localhost:666/api?icons=true


Invoke-RestMethod 'http://localhost:666/api?icons=true&fruit=kiwi,apple'


Invoke-RestMethod 'http://localhost:666/api?fruit=salad&sort=true'


Invoke-RestMethod 'http://localhost:666/api?fruit=salad&reversesort=true'

