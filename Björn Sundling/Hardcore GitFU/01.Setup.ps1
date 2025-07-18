break # avoid F5..


#region demo 1 - set editor
git config --global core.editor "code --wait"

code --help | Select-Object -First 15
##  Set the editor as it _should_ be - _always_ use vscode
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait --merge $REMOTE $LOCAL $BASE $MERGED'
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
#endregion




#region demo 2 - Dude, wheres my config?
git config --list --show-origin --show-scope

## Somewhat better looking...
git config --list --show-origin --show-scope | % {
    [pscustomobject]@{
        Scope = $_.split("`t")[0]
        Origin = $_.split("`t")[1] -replace '^file:',''
        Setting = $_.split("`t")[2].Split('=')[0]
        Value = $_.split("`t")[2].Split('=')[1]
    }
}

## Somewhat better looking, but with super easy and readable RegEx.
$pattern = '^(?<scope>[a-z]+)\s*file:(?<path>[^\t]*)\s+(?<setting>[^=]+)=(?<value>.*)$'
git config --list --show-origin --show-scope | % {
    $null = $_ -match $pattern
    $r = $Matches
    switch -regex ($r['scope']) {
        '^s' { $s = "`e[31m$_`e[0m" }
        '^g' { $s = "`e[33m$_`e[0m" }
        '^l' { $s = "`e[32m$_`e[0m" }
    }
    [pscustomobject]@{
        Scope = $s
        Origin = $r['path']
        Setting = $r['setting']
        Value = $r['value']
    }
}
#endregion






#region demo 3 - includeIf - add extra configuration places.
code (Resolve-Path ~\.gitconfig).Path
# [user]
# 	email = bjorn.sundling@gmail.com
# 	name = Björn Sundling

# # All work Git repositories are in a subdirectory of ~/work.
# # All other Git repositories are outside ~/work.
# [includeIf "gitdir:~/work/"]
#     path = .gitconfig.work
code (Resolve-Path ~\.gitconfig.work).Path

# You can observe the difference by changing to a Git directory under ~/work, and running:
Push-Location C:\GitHub\AdvaniaSE\PowerShellAdvancedFundamentals\
git config user.email

Set-Location C:\GitHub\bjompen\PSConf2025-GitFu
git config user.email

Pop-Location
#endregion








#region demo 4 - Enable code signing
# Generate new key pair
$k = ssh-keygen.exe -f "myKey$(Get-Random -Minimum 10001 -Maximum 99999)"
# $k[1] -match "(?<=\.ssh\/)(?<fileName>[a-z0-9_.]+)$" 
$k[1] -match "Your identification has been saved in (?<fileName>[a-z0-9_.]+)$" 
$fileName = $Matches['fileName']

# Add the key to your GitHub profile
Get-Content .\$fileName.pub | clip
Start-Process https://github.com/settings/keys # make sure it is a signing key!

# Set git to use signing key
git config --global gpg.format ssh
git config --global user.signingkey $((Resolve-Path -Path "~\.ssh\$fileName.pub").Path)

# Use -S _CAPITAL S_ to sign a commit.

git commit -S -m 'signed commit is signed'

# Skip the -S need..
git config --global commit.gpgsign true
#aditionally force sign tags
git config --global tag.gpgsign true

# In order to verify signature locally.
"$(git config --get user.email) namespaces=""git"" $(gc $((Resolve-Path -Path "~\.ssh\$fileName.pub").Path))" | Out-File ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
git show --show-signature

# And remember your private key password -> keepass_adv -> General -> SSH passphrase

# Add signing to vscode: Settings -> search for 'enablecommitsigning'
# this will automagically pass the -S flag on commit

# For Mac users, the GPG Suite allows you to store your GPG key passphrase in the macOS Keychain.
# For Windows users, the Gpg4win integrates with other Windows tools.
#endregion



#region demo 5 - Create aliases
## Effectively just replaces the alias with text - parameters magically work!
git config --global alias.<alias> '<command>'
git config --global alias.cln 'clean -d -x -n'
git config --global alias.sc 'commit -S -m'
# Even works with non git stuff:
 git config --global alias.svc '!pwsh.exe -c "Get-Service xbox*"'
## Remove alias
git config --global --unset alias.svc
#endregion





#region demo 6 - Create good gitignores
$exclusions = (Invoke-RestMethod 'https://www.toptal.com/developers/gitignore/api/list') -split '[,\n]' | Out-ConsoleGridView -OutputMode Multiple
Invoke-RestMethod -Uri "https://www.toptal.com/developers/gitignore/api/$($exclusions -join ',')" | Out-File .gitignore
git add .gitignore
git commit -S -m 'add gitignore'

# If you have checked in files that you just added to your gitignore you can remove them:
git rm -r --cached .
git add .
#endregion
