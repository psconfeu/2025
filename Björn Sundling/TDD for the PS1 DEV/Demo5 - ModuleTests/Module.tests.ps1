BeforeDiscovery {
    Remove-Module 'Demo4.Module' -Force -ErrorAction SilentlyContinue
    Import-Module '.\Demo4.Module.psm1' -Force
    
}

Describe "Module $ModuleName" {
    Context 'Public functions' {
        $ExportedFunctions = (Get-Module 'Demo4.Module').ExportedCommands.Keys

        $commonParam = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        $paramTestCase = foreach ($k in $ExportedFunctions) {
            $f = (Get-Command $k).Parameters
            foreach ($p in @(($f.Keys).Where({$_ -notin $commonParam}))) {
                [psobject]@{
                    FunctionName = $k
                    Parameter    = $p
                }
            }
        }

        BeforeAll {
            $ApprovedVerbs = (Get-Verb).Verb
        }

        It 'All public functions should have approved verb: function <_>' -TestCases $ExportedFunctions {
            $_.Split('-')[0] | Should -BeIn $ApprovedVerbs
        }

        # It 'All public functions parameters should be CamelCase: function <_.FunctionName> param <_.Parameter>' -TestCases $paramTestCase {
        #     $_.Parameter | Should -MatchExactly '^[A-Z]'
        # }
    }
}