#Region './Public/Convert-JSImageToBitMap.ps1' -1

function Convert-JSImageToBitMap {
    param (
        $SourceFilePath,
        $DestinationFilePath
    )
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $file = Get-Item $SourceFilePath
    $convertfile = new-object System.Drawing.Bitmap($file.Fullname)
    $convertfile.Save($DestinationFilePath, "bmp")
}
#EndRegion './Public/Convert-JSImageToBitMap.ps1' 11
#Region './Public/Deploy-Workbook.ps1' -1

function Deploy-Workbook {
    param(
        [string]$MonitoringDir,
        [string]$workbookFileName
    )

    Write-Host "[$(Get-Date -Format t)] INFO: Deploying Azure Workbook $workbookFileName."
    Write-Host "`n"
    $workbookTemplateFilePath = "$MonitoringDir\$workbookFileName"
    # Read the content of the workbook template-file
    $content = Get-Content -Path $workbookTemplateFilePath -Raw
    # Replace placeholders with actual values
    $updatedContent = $content -replace 'rg-placeholder', $env:resourceGroup
    $updatedContent = $updatedContent -replace '/subscriptions/00000000-0000-0000-0000-000000000000', "/subscriptions/$($env:subscriptionId)"
    $updatedContent = $updatedContent -replace "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/$env:resourceGroup/providers/Microsoft.OperationalInsights/workspaces/xxxx", "/subscriptions/$($env:subscriptionId)/resourceGroups/$($env:resourceGroup)/providers/Microsoft.OperationalInsights/workspaces/$($env:workspaceName)"

    # Write the updated content back to the file
    Set-Content -Path $workbookTemplateFilePath -Value $updatedContent

    # Deploy the workbook
    try {
        New-AzResourceGroupDeployment -ResourceGroupName $Env:resourceGroup -TemplateFile $workbookTemplateFilePath -ErrorAction Stop
        Write-Host "[$(Get-Date -Format t)] INFO: Deployment of template-file $workbookTemplateFilePath succeeded."
    } catch {
        Write-Error "[$(Get-Date -Format t)] ERROR: Deployment of template-file $workbookTemplateFilePath failed. Error details: $PSItem.Exception.Message"
    }
}
#EndRegion './Public/Deploy-Workbook.ps1' 28
#Region './Public/Invoke-JSSudoCommand.ps1' -1

function Invoke-JSSudoCommand {
    <#
    .SYNOPSIS
    Invokes sudo command in a remote session to Linux
    #>
        param (
            [Parameter(Mandatory=$true)]
            $Session,

            [Parameter(Mandatory=$true)]
            [String]
            $Command
        )
        Invoke-Command -Session $Session {
            $errFile = "/tmp/$($(New-Guid).Guid).err"
            Invoke-Expression "sudo ${using:Command} 2>${errFile}"
            $err = Get-Content $errFile -ErrorAction SilentlyContinue
            Remove-Item $errFile -ErrorAction SilentlyContinue
            If (-Not $null -eq $err)
            {
                $err | Out-String | Write-Warning
            }
        }
    }
#EndRegion './Public/Invoke-JSSudoCommand.ps1' 25
#Region './Public/Set-JSDesktopBackground.ps1' -1

function Set-JSDesktopBackground {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

$code = @'
    using System.Runtime.InteropServices;
    namespace Win32{

        public class Wallpaper{
            [DllImport("user32.dll", CharSet=CharSet.Auto)]
            static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ;

            public static void SetWallpaper(string thePath){
                SystemParametersInfo(20,0,thePath,3);
            }
        }
    }
'@

Add-Type $code
[Win32.Wallpaper]::SetWallpaper($ImagePath)

}
#EndRegion './Public/Set-JSDesktopBackground.ps1' 27
#Region './Public/Show-K8sPodStatus.ps1' -1

function Show-K8sPodStatus {
param (
    [string]$kubeconfig,
    [string]$clusterName
)

while ($true) { 
    Write-Host "Status for $clusterName at $(Get-Date)" -ForegroundColor Green
    kubectl get pods -n arc --kubeconfig $kubeconfig
    Start-Sleep -Seconds 5 
    Clear-Host
}
}
#EndRegion './Public/Show-K8sPodStatus.ps1' 14
#Region './Public/Update-AzDeploymentProgressTag.ps1' -1

    function Update-AzDeploymentProgressTag {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ProgressString,
            [Parameter(Mandatory = $true)]
            [string]$ResourceGroupName,
            [Parameter(Mandatory = $true)]
            [string]$ComputerName
        )

        $tags = Get-AzResourceGroup -Name $ResourceGroupName | Select-Object -ExpandProperty Tags

        if ($null -ne $tags) {
            $tags['DeploymentProgress'] = $ProgressString
        } else {
            $tags = @{'DeploymentProgress' = $ProgressString }
        }

        $null = Set-AzResourceGroup -ResourceGroupName $ResourceGroupName -Tag $tags
        $null = Set-AzResource -ResourceName $ComputerName -ResourceGroupName $ResourceGroupName -ResourceType 'microsoft.compute/virtualmachines' -Tag $tags -Force
    }
#EndRegion './Public/Update-AzDeploymentProgressTag.ps1' 22
