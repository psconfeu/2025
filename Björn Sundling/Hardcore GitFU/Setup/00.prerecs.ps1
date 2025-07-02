$fullDir = gci PSConf2025-GitFu-Demo* | % FullName
New-PSDrive -Name PSConf-git -PSProvider FileSystem -Root $fullDir
cd PSConf-git:\
clear
