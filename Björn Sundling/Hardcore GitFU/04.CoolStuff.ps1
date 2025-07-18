break # avoid F5..


#region demo 1 - better git log
git log --graph --oneline
# graph shows relations, oneline shows less info
#endregion




#region demo 2 - better views and of branches, and sorting on last commited
git branch --column --all --sort committerdate

# bonus - Stupid formatting trick...
1..40 | git column --mode=column --padding=5
#endregion






#region demo 3 - Get some git metadata
git cat-file -p HEAD # Shows the metadata of the latest commit
# -p - pretty print
# -s - show size
# -t - show type
# Sometimes in order to user git terminology in PowerShell we need the "stop-parse" token: --%
git cat-file -s --% @
git cat-file -t --% @
#endregion





#region demo 4 - Simple file listings - less verbosity
## git diff
git diff HEAD~2 HEAD # Full change log
git diff HEAD~2 HEAD --compact-summary # just the deets

## git status
git status # full diff - what's changed
git status --short # shorter and cleaner


# ls-files also works in certain cases.. but not nearly as useful and not for scripting
git ls-files -t --full-name
# H - tracked file that is not either unmerged or skip-worktree
# S - tracked file that is skip-worktree
# M - tracked file that is unmerged
# R - tracked file with unstaged removal/deletion
# C - tracked file with unstaged modification/change
# K - untracked paths which are part of file/directory conflicts which prevent checking out tracked files
# ? - untracked file
# U - file with resolve-undo information
#endregion



#region demo 5 - git rev-parse
git rev-parse --show-toplevel

Join-Path -Path "$(git rev-parse --show-toplevel)" -ChildPath Setup

Push-Location .\Setup\DemoFunctions
git rev-parse --path-format=relative --show-toplevel
Pop-Location
#endregion



#region demo 6 - gitk
gitk
# can do most of the git searching as well.. but Guis are boring ;)
#endregion


# Autostash

# rerere