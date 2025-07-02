break # avoid F5..


# DETACHED HEAD: When HEAD points to a commit, not a branch. You can still work here, but if you do not create a pointer - git checkout -b <branch> - then this work will be deleted on garbage collection

#region demo 1 - Checking out a PR using only git commands!
## https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/checking-out-pull-requests-locally
git ls-remote # lists everything remote, including pull requests. PRs have HEADs
## Also works on random remote repos!
git ls-remote https://github.com/PowerShell/PowerShell.git | Select-String -Pattern '\s+refs/pull/' | Select-Object -First 10
git ls-remote https://github.com/PowerShell/PowerShell.git | ? {$_ -match ".*/\d/head"}
(git ls-remote https://github.com/PowerShell/PowerShell.git | ? {$_ -match ".*/merge$"}).count
git ls-remote https://github.com/PowerShell/PowerShell.git | ? {$_ -match ".*/head$"} |  Sort-Object -Property @{Expression={[int]($_.split('/')[-2])}} | select -Last 1


# git fetch origin pull/ID/head:BRANCH_NAME
git fetch origin refs/pull/242/head:newBranch
git switch newBranch
git push origin newBranch
# Pushing to the _actual_ PR? Dont know..
# Delete branch when done reviewing
git branch -D newBranch

# We could also do this without actually creating a local branch
git branch -v
# create local refs for all remotes
git fetch origin +refs/pull/*:refs/remotes/origin/pr/* # + is the force flag. Do we need it?
# Or just one
git fetch origin +refs/pull/242/head:refs/remotes/origin/pr/242/head
# Now we have more "local" branches:
git branch -a 
# And checkout in detached head state
git checkout remotes/origin/pr/242/head
#endregion




#region demo 2 - searching
git log -S 'Demo3Function1' # find every commit with a change that matches 'something'
git log -S 'demo3function1' # Note - Git is case sensitive



git log -G '[Dd]emo3[Ff]unction1' # Same as S but with regex

git log -G '[Dd]emo3[Ff]unction1' --diff-merges=on # Also show the actual change.
git log -S 'Demo3Function1' -p # -p also shows content

git log --oneline --follow ./SearchDemo.ps1 # Follow a file

git log -L 1,3:./SearchDemo.ps1 # Find every change relating to linenumber range

git log -L:Demo3Function1:./SearchDemo.ps1 # Find every change relating to a function. Uses RegEx and can be odd, but fortunately seems to work for PowerShell.

git grep -P '{{replace[1-6]}}' $(git rev-list --all) # Search all files through all of history using PCRE regex
#endregion





#region demo 3 - Clean up a dirty folder

#region generate garbage
'a garbage file is generated' | Out-File .\Garbage.demo
mkdir subDir
'another garbage file is generated' | Out-File .\subDir\garbage.file
'And more garbage files are generated' | Out-File .\Garbage.txt
#endregion

gc .\.gitignore # Ignore demo files

git clean -d -x -n
<#
-d - include directories
-x - Include files in gitignore
-X - _only_ files in gitignore
-n - dry run, show what would be removed
By default the setting clean.requireForce is true, and therefore we need the force flag to actually delete stuff
-f - Force
#>
git clean -d -x -f
#endregion







#region demo 4 - Clean up caches, empty branches etc.

# 1. Remove all branches on your GitHub fork. AFAIK you can not automate this on GitHub, but it may be possible.
# 2. Run the following. Remove --dry-run :)
git fetch --prune --dry-run
# Or - does the same thing..
git remote prune origin
# Now local branches will get the message:
#   Your branch is based on 'origin/branchName', but the upstream is gone.
#   (use "git branch --unset-upstream" to fixup)
git branch -vv
# Shows branches where origin is gone
# 3. This then filters the verbose list and force deletes the branches without remotes
# DANGERZONE: -d or --delete only deletes a branch if it is merged
# DANGERZONE: -D or --delete --force deletes a branch no matter if it is merged or not!
git branch --verbose | Where-Object {$_ -Match '\[gone]'} | ForEach-Object {
    $null = $_ -match '^(?:\s+)(?<branch>[^\s]+)'
    git branch --delete $matches['branch'] --force
}
# Lastly - force a garbage collection
git gc
#endregion








#region demo 5 - remove bad shit with git filter-repo and/or BFG
# In the beginning there was git filter-branch. I have never used that one, and it is somewhat deprecated and even git themselves recomend git filter-repo instead.

# BFG - Written in scala - which is javascript things. Needs a java runtime.
# Download from maven: https://repo1.maven.org/maven2/com/madgag/bfg/1.15.0/bfg-1.15.0.jar
# MAKE SURE LATEST COMMIT IS CLEAN!
# Needs a bare clone of a clean repo 
# git clone --mirror git://example.com/some-big-repo.git
git clone --mirror "$repoCreate.git"

java -jar .\bfg-1.15.0.jar # Shows help
java -jar .\bfg-1.15.0.jar --delete-files id_rsa  my-repo.git # deletes files

# Replacing f.eg passowrds needs a text file with filters to match and replacememnt values:
'password=REPLACE_WITH' | Out-File .\passwords.txt
java -jar ..\bfg-1.15.0.jar  --replace-text passwords.txt "./$($repoCreate.Split('/')[-1]).git" # replace text in file

cd some-big-repo.git
git reflog expire --expire=now --all # Reflog is the local list of where HEAD pointed. Expire simply purges all reflog history
git gc --prune=now --aggressive 

# Contact GitHub to clean up caches
# Make sure all collaborators update theur branches.
#endregion
