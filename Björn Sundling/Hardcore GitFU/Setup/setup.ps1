# No accidental runs please...
break


# Login to GitHub if you haven't already..
gh auth login

$demoSetupRepo = Join-Path -Path "$(git rev-parse --show-toplevel)".Replace('├╢','ö') -ChildPath Setup

#region Create and clone a new demo repo base
$demoRepoName = "PSConf2025-GitFu-Demo-$((New-Guid).Guid.Substring(0,8))"
$repoCreate = gh repo create $demoRepoName --description 'Demo branch setup for PSConf2025-GitFu' --private
git clone "$repoCreate.git"
cd $demoRepoName
#endregion


#region Make sure a main branch is setup
"Demo repo and branch setup for PSConfEU 2025 GitFu - Remo $demoRepoName" | Out-File 'readme.md'
'a garbage file is generated' | Out-File .\Garbage1.demo
'Password=MySuperSecretPassword' | Out-File .\SuperSecret.txt

git add .
git commit -m 'Add main and readme'
git push
#endregion


#region - Demo31 - Because history is good when it's old
git checkout -b 'Demo31'
Copy-Item $demoSetupRepo\DemoFunctions\SearchDemo.ps1
git add .
git commit -m 'Add Search Demo31'

#region The long road down... Create file changes.
(Get-Content .\SearchDemo.ps1).Replace('{{replace1}}', '[string]$name') | Out-File .\SearchDemo.ps1
git add .
git commit -m 'Change 1'

(Get-Content .\SearchDemo.ps1).Replace('{{replace7}}', 'Write-Host "Hello $Name"') | Out-File .\SearchDemo.ps1
'One more line' | Out-File .\SuperSecret.txt -Append
git add .
git commit -m 'Change 2'

(Get-Content .\SearchDemo.ps1).Replace('{{replace9}}', 'Write-Verbose "Hello $Name"') | Out-File .\SearchDemo.ps1

git add .
git commit -m 'Change 3'

(Get-Content .\SearchDemo.ps1).Replace('{{replace2}}', 'Write-Host "Hello $Name"') | Out-File .\SearchDemo.ps1
git add .
git commit -m 'Change 4'

(Get-Content .\SearchDemo.ps1).Replace('{{replace5}}', 'Write-Error "Hello $Name"') | Out-File .\SearchDemo.ps1
'One more line' | Out-File .\SuperSecret.txt -Append
git add .
git commit -m 'Change 5'

# Add a commit in the middle to make history loog good
git checkout main
'hello world' | Out-File .\MidHistoryFile.txt
git add .
git commit -m 'mid hist commit adding things and stuff'
git checkout Demo31

(Get-Content .\SearchDemo.ps1).Replace('{{replace3}}', 'Write-Output "Hello $Name"') | Out-File .\SearchDemo.ps1
git add .
git commit -m 'Change 6'

# Include a deleted file here too for bonus demo!
(Get-Content .\SearchDemo.ps1).Replace('{{replace8}}', 'This file is deleted!!') | Out-File .\DeletedFileDemo.ps1
git add .
git commit -m 'DeleteDemo'
##

(Get-Content .\SearchDemo.ps1).Replace('{{replace8}}', 'Write-Output "Hello $Name"') | Out-File .\SearchDemo.ps1
git add .
git commit -m 'Change 7'

## Delete Demo
Remove-Item .\DeletedFileDemo.ps1 -Force
##

(Get-Content .\SearchDemo.ps1).Replace('{{replace4}}', 'Write-Verbose "Hello $Name"') | Out-File .\SearchDemo.ps1
git add .
git commit -m 'Change 8'

(Get-Content .\SearchDemo.ps1).Replace('{{replace6}}', '[string]$name') | Out-File .\SearchDemo.ps1
git add .
git commit -m 'Change 9'
#endregion

git checkout main
git merge Demo31
git push
#endregion


#region - Demo32 - Generate garbage files
"*.zip`n*.dll`n*.tmp`n*.demo" | Out-File .gitignore
'One more line' | Out-File .\SuperSecret.txt -Append
git add .
git commit -m 'add gitignore'
git push
#endregion


#region - Demo33 - Create remote missing branches 
git checkout -b 'Demo33A'
'add file and stuff' | Out-File .\Demo33A.txt
git add .
git commit -m 'add file'
git push --set-upstream origin Demo33A
git checkout main

git checkout -b 'Demo33B'
'add file and stuff' | Out-File .\Demo33B.txt
git add .
git commit -m 'add file'
git push --set-upstream origin Demo33B
git checkout main

git checkout -b 'Demo33C'
'add file and stuff' | Out-File .\Demo33C.txt
git add .
git commit -m 'add file'
git push --set-upstream origin Demo33C
git checkout main

# go in to the github repo and delete the branches Demo33*
gh repo view --web

#endregion


#Region - Demo34 - Cleanup secret with BFG
git checkout -b 'Demo34'
'One more line' | Out-File .\SuperSecret.txt -Append
git add .
git commit -m 'secrets are bad for you'
git checkout main
git merge Demo34
git push
#endregion


#region - Demo21 - Create branch and add a file with a function and a spelling error
git checkout -b 'Demo21'
Copy-Item $demoSetupRepo\DemoFunctions\DemoFunctions.ps1
git add .
git commit -m 'Add branch Demo21'
git push --set-upstream origin Demo21
git checkout main
#endregion


#region - Demo 221 - Create branch and add a file with multiple commits
git checkout -b 'Demo221'
$rnd = $((New-Guid).Guid.Substring(0,8))
$randomData = "# Im generating random data! $rnd `n`n"
$randomData | Out-File .\Demo221WorkFile.md -Append
git add .
git commit -m "Add Demo221 $rnd"
git push --set-upstream origin Demo221
git checkout main
#endregion


#region - Demo 222 - Create branch and add a file with multiple commits
git checkout -b 'Demo222'
1.. 10 | % {
    $rnd = $((New-Guid).Guid.Substring(0,8))
    $randomData = "# Im generating random data! $rnd `n`n"
    $randomData | Out-File .\Demo222WorkFile.md -Append
    git add .
    git commit -m "Add Demo222 $rnd"
}

git push --set-upstream origin Demo222
git checkout main
#endregion


#region - Demo 23 - Create a file with at least ten commits to demo Bisect
git checkout -b 'Demo23'
1.. 10 | % {
    $rnd = $((New-Guid).Guid.Substring(0,8))
    $randomData = "# Im generating random data! $rnd `n`n"
    'Line one is unchanged' | Out-File .\Demo23WorkFile.md
    $randomData | Out-File .\Demo23WorkFile.md -Append
    'Line three is unchanged'  | Out-File .\Demo23WorkFile.md -Append
    git add .
    git commit -m "Add Demo23 $rnd"
}

git checkout main
git merge Demo23
#endregion


#region - Demo25 - Create branch and add a file with a function and a spelling error
git checkout -b 'Demo25'
$badFormat = (Get-Content $demoSetupRepo\DemoFunctions\DemoFunctions.ps1) -replace '^\s+',''
$badFormat | Out-File .\DemoFunctionsFormat.ps1

git add .
git commit -m 'Add branch Demo25'
git push --set-upstream origin Demo25
git checkout main
#endregion

git push




# Delete repo.. DANGER! 
cd ..
rmdir $demoRepoName -Recurse -Force
# gh auth refresh -h github.com -s delete_repo
gh repo delete $demoRepoName --yes