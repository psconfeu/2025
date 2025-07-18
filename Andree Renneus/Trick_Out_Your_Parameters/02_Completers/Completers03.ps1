using namespace System.Management.Automation

Register-ArgumentCompleter -CommandName Get-TestCompletion03 -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $Names = @(
        'Alice'
        'Bob'
        'Charlie'
    )
    foreach ($item in $Names) {
        if ($item -like "$wordToComplete*") {
            [CompletionResult]::new(
                $item,
                $item,
                'ParameterValue',
                $item
            )
        }
    }
}

function Get-TestCompletion03 {
    [CmdletBinding()]
    param(
        [string]$Name,
        [int]$Age
    )
    $PSBoundParameters
}

# Complete 'Get-TestCompletion03 -Name '

Register-ArgumentCompleter -Native -CommandName ping -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $ServerList = @(
        'google.com'
        'microsoft.com'
        'github.com'
        'stackoverflow.com'
        'localhost'
    )
    foreach ($server in $ServerList) {
        if ($server -like "$wordToComplete*") {
            [CompletionResult]::new(
                $server,
                $server,
                'ParameterValue',
                $server
            )
        }
    }
}
complete 'ping '



# https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion#enable-tab-completion
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# complete 'winget s'

# https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
            [CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# complete 'dotnet b'


# can register a completer for functions you don't control directly.

Register-ArgumentCompleter -CommandName Invoke-RestMethod -ParameterName Uri -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $ServerList = @(
        'google.com'
        'microsoft.com'
        'github.com'
        'stackoverflow.com'
        'localhost'
    )
    foreach ($item in $ServerList) {
        if ($item -like "$wordToComplete*") {
            [CompletionResult]::new(
                $item,
                $item,
                'ParameterValue',
                $item
            )
        }
    }
}

# complete 'Invoke-RestMethod -Uri goo'


<#
https://github.com/PowerShell/PowerShell-RFC/pull/386
https://github.com/PowerShell/PowerShell-RFC/blob/b6596bcca27cc166081b27b7d6dc1105736525e7/Draft-Accepted/feedback_completer_auto_discovery.md
#>
