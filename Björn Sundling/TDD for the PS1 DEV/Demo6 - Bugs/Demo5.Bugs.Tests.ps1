BeforeAll {
    Remove-Item function:\Get-Fruit -Force -ErrorAction SilentlyContinue
    Remove-Item function:\CallApi -Force -ErrorAction SilentlyContinue
    . $PSScriptRoot\Demo5.Bugs.ps1
}

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
            # Demo 1 - add a mock
            # What is wrong with this? It is _not_ a unit test. What happens if our API goes down?
            # Create a wrapper around the API call to be able to mock it
            # Demo rename MyApi.ps1

            # mock -CommandName CallApi -MockWith { Return 'Banana' }
            Get-Fruit | Should -Be 'Banana'
        }

# region Demo 2 - more mock with parameter filter
        $TestCases = @(
            @{
                ParameterValue = 'Apple'
                Expected = 'Apple'
            },
            @{
                ParameterValue = 'Banana'
                Expected = 'Banana'
            },
            @{
                ParameterValue = 'Kiwi'
                Expected = 'Kiwi'
            }
        )

        It 'Given parameter "-Fruit <_.ParameterValue>" it should return <_.Expected>' -TestCases $TestCases {
            mock -CommandName CallApi -MockWith { Return 'Apple' } -ParameterFilter { $Fruit -eq 'Apple' }
            mock -CommandName CallApi -MockWith { Return 'Banana' } -ParameterFilter { $Fruit -eq 'Banana' }
            mock -CommandName CallApi -MockWith { Return 'Kiwi' } -ParameterFilter { $Fruit -eq 'Kiwi' }

            Get-Fruit -Fruit $ParameterValue | Should -Be $Expected
        }
# endregion

# region Demo 3
        # Extending test cases to support Icons
        
        $TestCases = @(
            @{
                ParameterValue = 'Apple'
                Expected = '🍎'
            },
            @{
                ParameterValue = 'Banana'
                Expected = '🍌'
            },
            @{
                ParameterValue = 'Kiwi'
                Expected = '🥝'
            }
        )

        It 'Given parameter "-Fruit <_.ParameterValue>" and "-Icons" it should return <_.Expected>' -TestCases $TestCases {
            mock -CommandName CallApi -MockWith { Return '🍎' } -ParameterFilter { $Fruit -eq 'Apple' -and $Icons -eq $true}
            mock -CommandName CallApi -MockWith { Return '🍌' } -ParameterFilter { $Fruit -eq 'Banana' -and $Icons -eq $true}
            mock -CommandName CallApi -MockWith { Return '🥝' } -ParameterFilter { $Fruit -eq 'Kiwi' -and $Icons -eq $true}

            Get-Fruit -Fruit $ParameterValue -Icons | Should -Be $Expected

        }
#endregion
    }


    Context 'Bugs' {
        it 'Bug report #1 - Peaches results in an error' {
            Get-Fruit -Fruit 'Peach' | Should -be 'Peach'
        }
        it 'Bug report #1 - Peaches results in an error - test with icons' {
            Get-Fruit -Fruit 'Peach' -Icons | Should -be '🍑'
        }
    }
}

