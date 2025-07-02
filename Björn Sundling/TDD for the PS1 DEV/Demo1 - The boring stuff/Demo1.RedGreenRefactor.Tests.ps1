# Step 1 - Just go green


# 1. Describe - Context - It - Banana
# 2. BeforeAll - Remove and Import function


# New-Fixture -Name RedGreenRefactor










BeforeAll {
    Remove-Item function:\Get-Fruit -Force -ErrorAction SilentlyContinue
    . $PSScriptRoot\Demo1.RedGreenRefactor.ps1
}

Describe 'Fruit API module' {
    Context 'Get-Fruit' {
        It 'Given no input, should output Banana' {
            Get-Fruit | Should -Be 'Banana'
        }
    }
}
