function Get-NorthstarGoal {
    Write-Host "--- Welcome to the North Star Career Prompt Generator ---" -ForegroundColor Cyan
    Write-Host "(Please separate with a comma if you want to list multiple inputs)" -ForegroundColor Cyan

    $Name = Read-Host "What is your name?"
    $CurrentRole = Read-Host "What is your current role?"
    $Motivation = Read-Host "What motivates you? (e.g., helping others, solving problems, building cool stuff)"
    $Drains = Read-Host "What drains your energy? (e.g. political discussions, long meetings)"
    $Strengths = Read-Host "What are your top 3 strengths? (e.g. empathy, strategic thinking)"
    $FlowWork = Read-Host "What kind of work makes you lose track of time? (e.g. coding, solving problems)"
    $Reputation = Read-Host "What kind of work would you like to be known for? (e.g. Security Skills)"
    $PersonalGoals = Read-Host "What are your personal goals/commitments that influence your work life balance? (e.g. family, volunteering)"
    $Professions = Read-Host "What professions are you interested in? (e.g. security analyst, security researcher)"
    $AdmiredSkills = Read-Host "What skills do you admire? What skills would you like to have? (e.g. reverse engineering, KQL skills)"

    $Prompt = @"
You are a career development AI assistant. Based on the following user profile, generate 5 possible career paths for $name. Each path should be inspired by different aspects of the profile: one based on motivation, one on strengths, one on admired skills, one on environmental preferences (e.g., energy drains), and one on personal goals. But all paths should be at least inspired somewhat by all aspects.

For each career path:
- Provide a brief description.
- Outline 3 potential roles that serve as stepstones to get to the final destination role
- Recommend three key strengths the user should develop to succeed in that path.

User Profile:
- Current Role: $CurrentRole
- Motivated by: $Motivation
- Drained by: $Drains
- Top Strengths: $Strengths
- Flow State Work: $FlowWork
- Desired Reputation: $Reputation
- Personal Goals/Commitments: $PersonalGoals
- Interested Professions: $Professions
- Admired Skills: $AdmiredSkills
"@

    Write-Host ""
    Write-Host "Copy and paste the following prompt into Copilot or ChatGPT:" -ForegroundColor Yellow
    Write-Output $Prompt
    return $Prompt
}

Get-NorthstarGoal