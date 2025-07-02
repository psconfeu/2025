break # avoid F5..


#region demo 1 - Change more than one line, commit only one change
git checkout Demo21
code . # edit DemoFunctions bottom...

git add --patch
# y - stage this hunk
# n - do not stage this hunk
# q - quit; do not stage this hunk or any of the remaining ones
# a - stage this hunk and all later hunks in the file
# d - do not stage this hunk or any of the later hunks in the file
# s - split the current hunk into smaller hunks
# e - manually edit the current hunk
# p - print the current hunk
# ? - print help

git diff # what is _not_ commited - The lines we said "no" to
git diff --staged # What is commited - The lines we said "yes" to

git diff --word-diff # Bonus - show words instead of lines

# Keep the staged changes - the lines we added - stash the others - to be able to run tests on _only_ my change
git stash --keep-index 
git stash apply

# once done - push the things
git commit -m 'fixes spelling error'
git add .
git commit -m 'fixes code'
git push
git checkout main
#endregion





#region demo 2 - Squashing - taking more commits and combining them to one - makes a cleaner history
git checkout Demo221

# edit something in the Demo221WorkFile.md
git add .
git commit -m 'add stuff'


git rebase -i HEAD~<n> # By using relative commits
git rebase -i a48de8a4d81ce0d5f5380ed7062ab6258f293740 # By using commit ids


# Easier way to clean up history is a soft reset
git checkout Demo222
# find the branch commit
git log --graph --oneline

# reset it and renew everything from there.
git reset --soft d0ab291
git commit -m 'using a soft reset'
# This requires a force push though.. 
git push --force

git checkout main
#endregion








#region Reset, restore, and revert!
Start-Process 'https://git-scm.com/docs/git#_reset_restore_and_revert'

git restore <file> # restores a file from last commit without committing anything 
git reset # moves the tip of the branch somewhere else. Reqrite history.
git revert HEAD~1 # Creates a new commit reverting the changes from the named commit.   
#endregion


#region demo 3 - Restore file(s) 
# Get the commit history
git log --oneline ./Demo23WorkFile.md

# If you are working locally you may also use the reflog (only local and "Where did HEAD point?")
git reflog

## Show the content at the given commit
git show da5cb2b:./Demo23WorkFile.md
# remember - Git is case sensitive, PowerShell isnt. weird errors may occur!
git show da5cb2b:./demo23workfile.md
# Exists on disk but not in commit it was just said to exist...


# Or use git bisect to find the evil stuff!
git bisect start
git bisect bad HEAD
git bisect good da5cb2b
# If the content is good
git bisect good
# If the content is bad
git bisect bad

# When done, take note of the commit ID
git bisect reset

## Restore the file
git restore --source=6b67228fdb810e4293e3a44de808125e48e188c7 Demo23WorkFile.md

git restore --patch --source=07df6af6efa89497dfe77e806d195b5d14cb7c48 Demo23WorkFile.md # Restore parts of a file

## Note - restore is experimental - can change.. but it has been for years.
## Note - VSCode doesn't seem to notice the change in active window - close and reopen
#endregion




#region demo 4 - Cherrypicking
## Take one commit from branch A and introduce it to branch B
Start-Process https://www.geeksforgeeks.org/git-cherry-pick/
#endregion



#region demo 5 - Git blame and ignore-rev
git checkout Demo25

# doing code cleanup or refactor? Add a .git-blame-ignore-revs file in the root to cleanup the blame
git blame DemoFunctionsFormat.ps1

#needs full hash! 
git log --oneline --no-abbrev-commit

'748e2098edf446164e4b5ae6b3eae4331d024c20' | Out-File .git-blame-ignore-revs
git blame --ignore-revs-file .git-blame-ignore-revs DemoFunctionsFormat.ps1
# Also supported in VSCode (according to Justin) and GitHub

git add .
git commit -m 'add git-blame-ignore-revs'
git push
git checkout main
#endregion


#region fetch vs. pull
## Fetch gets the remote changes and pulls them to your computer
## Pull also does a merge from the remote now synced branch to the branch you are on.
## Merge is default done in fast forward, but can be changed if needed.
## You always have "two" copies of the repo on your computer: The "remote bucket" and the local. 
## In reality there is of course only one set of data and a bunch of refs. 
#endregion

#region Demo 6 - Extra - find and restore deleted file
## Search for deleted file
git log --diff-filter=D --summary --oneline # get all deleted files

git log --diff-filter=D --summary --oneline -- *eDemo.ps1  # filter for pattern - is weird, but works sometimes
git log --diff-filter=D --summary --oneline -- DeletedFileDemo.ps1

## important to remember - the log outputs when the file was deleted. In order to restore we need the parent of the delete commit
git log --pretty=%P --max-count=1  <commit hash>
## or
git log --diff-filter=D --summary --pretty=%P -- *De* # %P is parent. More formating possible.

# Or even more hardcore - combine pretty and other output parameters are possible:
git log --diff-filter=D --pretty=format:"Hash: %Cgreen%H%nParent: %Cred%P%nCommit message: %B" --name-status


git restore --source <commit hash> <file> 
#endregion
