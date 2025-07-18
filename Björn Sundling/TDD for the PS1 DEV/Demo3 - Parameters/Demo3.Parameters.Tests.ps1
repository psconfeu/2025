BeforeAll {
    Remove-Item function:\Get-Fruit -Force -ErrorAction SilentlyContinue
    . $PSScriptRoot\Demo3.Parameters.ps1
}

# Describe 'Fruit API module' {
#     Context 'Get-Fruit' {
#         It 'Given no input, should output Banana' {
#             Get-Fruit | Should -Be 'Banana'
#         }
#     }
# }









# Demo 2.1 - Add a param test

# Describe 'Fruit API module' {
#     Context 'Get-Fruit - Parameters' {
#         It 'Get-Fruit Should have parameter Fruit' {
#             Get-Command Get-Fruit | Should -HaveParameter 'Fruit'
#         }
#     }
    
#     Context 'Get-Fruit' {
#         It 'Given no input, should output Banana' {
#             Get-Fruit | Should -Be 'Banana'
#         }
#     }
# }















# Demo 2.2 - Refactor a test - Normally isn't "ok" in TDD - But Pester and PowreShell parameter validation is cool!

# Describe 'Fruit API module' {
#     Context 'Get-Fruit - Parameters' {
#         It 'Get-Fruit Should have parameter Fruit' {
#             Get-Command Get-Fruit | Should -HaveParameter 'Fruit' -Type 'String'
#         }
#     }
    
#     Context 'Get-Fruit' {
#         It 'Given no input, should output Banana' {
#             Get-Fruit | Should -Be 'Banana'
#         }
#     }
# }










# Demo 2.3 - Add more parameters and change to test cases.
# Parameters can be used for semantic versioning!

Describe 'Fruit API module' {
    Context 'Get-Fruit - Parameters' {
        $TestCases = @(
            @{
                Name = 'Fruit'
                Mandatory = $false
                Type = 'string'
            },
            @{
                Name = 'Icons'
                Mandatory = $false
                Type = 'Switch'
            }
        )

        It 'Get-Fruit Should have parameter <_.Name>' -TestCases $TestCases {
            Get-Command Get-Fruit | Should -HaveParameter $_.Name -Type $_.Type -Mandatory:$_.Mandatory
        }
    }
    
    Context 'Get-Fruit' {
        It 'Given no input, should output Banana' {
            Get-Fruit | Should -Be 'Banana'
        }
    }
}
