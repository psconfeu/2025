BeforeAll {
    Remove-Item function:\Get-Fruit -Force -ErrorAction SilentlyContinue
    Remove-Item function:\CallApi -Force -ErrorAction SilentlyContinue
    . $PSScriptRoot\Demo4.MoreFunctionality.ps1
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
            mock -CommandName CallApi -MockWith { Return 'Banana' }
            Get-Fruit | Should -Be 'Banana'
        }


        
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
    }
}

