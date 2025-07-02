Find-Module YAPG | Install-Module

New-YapgPassword




New-YapgPassword -WordCount 2




New-YapgPassword -AddChars





New-YapgPassword -Leet





New-YapgPassword -Leet -AddChars -Capitalize -WordCount 5 -Passwords 10







New-YapgPassword -Dictionary (Join-Path (split-path (Get-Module yapg | % path )) -ChildPath sv-SE.dic)

