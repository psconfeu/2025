using namespace System.Management.Automation
class BuiltInSounds : IValidateSetValuesGenerator {
    static [string[]] $Sounds
    static BuiltInSounds() {
        $CachedSounds = Get-ChildItem -File C:\Windows\Media\*.wav
        # simulate api call delay
        Start-Sleep -Seconds 2
        [BuiltInSounds]::Sounds = $CachedSounds.BaseName
    }
    [string[]] GetValidValues() {
        return [BuiltInSounds]::Sounds
    }
}
function Start-Sound {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet([BuiltInSounds], ErrorMessage = '{0} Not a valid sound file, try one of the following: {1}')]
        [string] $Sound
    )
    $BasePath = 'C:\Windows\Media\'
    $SoundPath = Join-Path -Path $BasePath -ChildPath ($Sound + '.wav')
    Get-Item $SoundPath
    <#
    # wired for audio? probably not.
    if (-not ('System.Windows.Media.MediaPlayer' -as [type])) {
        Add-Type -AssemblyName PresentationCore
    }
    $mediaPlayer = [System.Windows.Media.MediaPlayer]::new()
    $mediaPlayer.Open($SoundPath)
    $mediaPlayer.Play()
    #>
}
Complete 'Start-Sound -Sound Alarm'
Complete 'Start-Sound -Sound *Noti*'
Start-Sound tada
