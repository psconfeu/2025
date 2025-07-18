[DscResource()]
class DesktopBackground : DSCResource {
  [DscProperty(Key)]
  [string] $ImagePath

  [DscProperty()]
  [bool] $Ensure

  DesktopBackground() {}

  [void] Set() {
    Set-JSDesktopBackground -ImagePath $this.ImagePath
  }

  [bool] Test() {
    $current = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop').WallPaper
    return ($current -eq $this.ImagePath)
  }

  [DesktopBackground] Get() {
    $current = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop').WallPaper
    return [DesktopBackground]@{
      ImagePath = $current
      Ensure    = $true
    }
  }
}