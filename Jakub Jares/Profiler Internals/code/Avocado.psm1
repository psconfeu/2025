function Get-Avocado {
    Get-Emoji -Emoji avocado
}

function Get-Emoji ($Emoji) {
    if (Test-ValidEmoji -Emoji $Emoji) {
        Get-EmojiInternal -Emoji $Emoji
    } else {
        Write-Error "Invalid emoji: $Emoji"
    }
}

function Test-ValidEmoji ($Emoji) {
    $emoji = Get-EmojiInternal -Emoji $Emoji
    
    return $null -ne $emoji
}

Export-ModuleMember -Function Get-Avocado, Get-Unicorn













































function  Get-EmojiInternal ($Emoji) {
    $ProgressPreference = 'SilentlyContinue'

    $uri = "https://www.emoji.family/api/emojis?search=$Emoji"
    $r = Invoke-RestMethod -Method GET -Uri $uri -UseBasicParsing 
    $r | Where-Object { $_.annotation -eq $Emoji} | Select-Object -ExpandProperty emoji
}
