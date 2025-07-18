# Demo 01. Setup - 6 demos

- A clean git setup with no configuration. VM, WSL, or container?

# Demo 02. Add and Restore code - 6 demos

- Repo _must_ exist on GitHub!
- Repo with multiple branches
    - Main
    - BranchA
    - BranchB
    - CherryA
    - CherryB
- Files with different content. txt files or ps1?
    - Demo 1. Spelling error. fix this while adding code. `--patch` to only add one change.
        - Branch Demo21
    - Demo 2. interactive rebase with squash. One branch from main with more commits _in_ main.
        - Branch Demo221
    - Demo 2. rewrite using reset --soft. One branch from main with multiple commits.
        - Branch Demo222
    - Demo 3. One file needs at least a history of 10 commits with more than one line change to demo bisect and restore 
        - Branch main
        - FILE Demo23WorkFile.md
    - Demo 5. One branch must be bad formatting to demo .git-blame-ignore-revs
        - Branch Demo25
    - Demo 6. Repo on GitHub must have at least on PR open

# Demo 03. Maintenance - 4 demos

- At least one file must have a function with more than one change in history
    - Branch main
- .gitignore file with some contents
    - Branch main
- A script to generate garbage we can use to do some cleanup using git clean
    - In demo script
- A separate repo clone with dead / gone remotes
    - Demo33* branches gone from GitHub
- A file with something to clean using BFG
    - SuperSecret.txt - In all kinds of places.

# Demo 04. Cool stuff - 5 demos

