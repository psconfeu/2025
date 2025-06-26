Import-Module ScriptTools -Force
<#
psedit (Get-Module ScriptTools).Path

cd C:\Users\soost\OneDrive\PS\PSConfEU

$psISE.CurrentPowerShellTab.Files.RemoveAt(0)

cls
#>
return
###########################################################################
#
#region Search-Property
#
###########################################################################

$opsys = Get-CimInstance -ClassName Win32_OperatingSystem # -ComputerName comp1, comp2...
$opsys | Format-List -Property *

$opsys | Format-List -Property *Oper*

$opsys | Search-Property -Pattern Oper

$opsys.ToString()

$opsys | Search-Property -pattern $env:COMPUTERNAME

$opsys | Search-Property -pattern Oper -ObjectNameProp CSName -CaseSensitive -ExcludeProperty CimInstanceProperties
$opsys | Search-Property -pattern Oper -ObjectNameProp CSName -CaseSensitive -ExcludeProperty CimInstanceProperties -SearchInPropertyNames 
$opsys | Search-Property -pattern Oper -ObjectNameProp CSName -CaseSensitive -ExcludeProperty CimInstanceProperties -SearchInPropertyNames -ExcludeValues


$adobjects = Import-Clixml -Path .\adobjects.xml
$adobjects | fl

$adobjects | Search-Property -Pattern "<sn>"
$adobjects | Search-Property -Pattern "<sn>" -ObjectNameProp DisplayName
$adobjects | Search-Property -Pattern "<givenName> <sn>" -ObjectNameProp DisplayName

$adobjects | Search-Property -Pattern "@" -ObjectNameProp DisplayName

$adobjects | Search-Property -Pattern "^\d{3}$" -ObjectNameProp DisplayName
$adobjects | Search-Property -Pattern "^\d{3}$" -ObjectNameProp DisplayName -IgnoreCollections

# Tech used:
$adobjects[0].psobject.Properties | Format-Table -Property Name, MemberType, Value 

[regex]::Replace("Windows PowerShell 5.2, PowerShell 7.5", "\d+\.\d+", {[double]$args[0].value + 0.1})

<#
            if(!$LiteralSearch -and $origpattern  -match "<[^>]+>"){
                $Pattern = [regex]::Replace($origpattern, "<([^>]+)>", {[regex]::Escape($o.($args[0].value -replace "<|>"))})
            }
#>
#endregion
###########################################################################
#
#region Compare-ObjectProperty
#
###########################################################################

$refObject = [pscustomobject]@{
                    Name = "First Object"
                    OnlyAtRef = "somevalue"
                    Different = "Value1"
                    Equal = "equal value"
                    EqualArray = 1,2,3,4
                    DiffArray  = 1,2,3
                    HashPropEqual = @{
                                        One = 1
                                        Two = 2
                                    }
                    DiffHash = @{
                                    Key1 = 1
                                    Key2 = 2
                                }
                    PropObjEqual = [pscustomobject] @{
                                    Prop1 = 'one'
                                    Prop2 = 'two'
                                }
                    PropObjDiff = [pscustomobject] @{
                                    Prop1 = 'one'
                                    Prop2 = 222
                                    Prop3 = 'three'
                                }
                    EmptyEqual = $null
                    EmptyRefOnly = $null
                    EqualScriptBlock = {get-date}
                    DiffScriptBlock = {get-date}
                }

$diffObject = [pscustomobject]@{
                    Name = "Second Object"
                    OnlyAtDiff = "somevalue"
                    Different = "Value2"
                    Equal = "equal value"
                    EqualArray = 1,2,3,4
                    DiffArray  = 1,2,4
                    HashPropEqual = @{
                                        One = 1
                                        Two = 2
                                    }
                    DiffHash = @{
                                    Key1 = 1
                                    Key2 = 3
                                }
                    PropObjEqual = [pscustomobject] @{
                                    Prop1 = 'one'
                                    Prop2 = 'two'
                                }
                    PropObjDiff = [pscustomobject] @{
                                    Prop1 = 'one'
                                    Prop2 = 333
                                    Prop4 = 'four'
                                }
                    EmptyEqual = $null
                    EmptyDiffOnly = $null
                    EqualScriptBlock = {get-date}
                    DiffScriptBlock = {1 + 1}
                }


Compare-ObjectProperty -ReferenceObject $refObject -DifferenceObject $diffObject 
Compare-ObjectProperty -ReferenceObject $refObject -DifferenceObject $diffObject -NameProperty Name -IncludeEqual

Compare-ObjectProperty -ReferenceObject $refObject -DifferenceObject $diffObject -NameProperty Name -IncludeEqual -Hide Empty
Compare-ObjectProperty -ReferenceObject $refObject -DifferenceObject $diffObject -NameProperty Name -IncludeEqual -Hide BothEmpty
Compare-ObjectProperty -ReferenceObject $refObject -DifferenceObject $diffObject -NameProperty Name -IncludeEqual -Hide NonEmpty

Compare-ObjectProperty -ReferenceObject $refObject -DifferenceObject $diffObject -NameProperty Name -IncludeEqual -ExcludeDifferent

# Tech used:
<#
What is "Empty"?
    <Prop doesn't exist> -or 
    $null -eq $ra -or
    '' -eq $ra -or
    (($ra -is [collections.ilist] -or $ra -is [Collections.IDictionary]) -and $ra.count -eq 0) -or
    $ra -is [System.DBNull]

Recursion
$prop_r = [pscustomobject] @{one = 1; two = 2}
$prop_d = [pscustomobject] @{one = 1; two = 2}
$prop_r -eq $prop_d

--> Endless loops
How does a scriptblock look like?
    ({ 1 + 1}).ast.Parent.Parent.Parent.Parent.Parent.parent.parent

#>
#endregion
###########################################################################
#
#region Update-Property (actually does Update-Hash as well...)
#
###########################################################################

$setAdUserSplatting = @{}

Update-Property -object $setAdUserSplatting -propname DisplayName -value 'Tibor Soós'
Update-Property -object $setAdUserSplatting -propname Enabled -value $true -passthru

Update-Property -object $setAdUserSplatting -propname Replace -value @{proxyAddresses = "SMTP:tibor.soos@mycomp.com"} -passthru
$setAdUserSplatting.Replace

Update-Property -object $setAdUserSplatting.Replace -propname proxyAddresses -value "smtp:tsoos@mycomp.com" -passthru

Update-Property -object $setAdUserSplatting -propname Replace -value @{proxyAddresses = "smtp:powershellguru@mycomp.com"} 
$setAdUserSplatting.Replace

Update-Property -object $setAdUserSplatting -propname DisplayName -value 'Tibor Soos' -passthru -force

Update-Property -object $setAdUserSplatting -propname Clear -value Title, Department -passthru
Update-Property -object $setAdUserSplatting -propname Clear -value Department, Manager -passthru

Set-ADUser -Identity tsoos @setAdUserSplatting

#############################################

<#
    - Count of valid items
    - Approvers: Unique set of managers of all Owners
    - DN for each owner on the item
#>

$Ticket = @{
            TicketNumber = 12345
            ShortDescription = "Request for new privileged accounts"
            RequestedItems = @(
                                    @{
                                        ItemNumber = 1
                                        AccountName = "AdminTS"
                                        Owner = "Tibor Soos"
                                    },
                                    @{
                                        ItemNumber = 2
                                        AccountName = "CloudAdminTS"
                                        Owner = "Tibor Soos"
                                    },
                                    @{
                                        ItemNumber = 3
                                        AccountName = "AdminED"
                                        Owner = "Ellie Doe"
                                    }
                                )
        }

$adobjects = Import-Clixml -Path .\adobjects.xml

$adobjectHash = @{}
foreach($ado in $adobjects){$adobjectHash.($ado.displayname) = $ado}

foreach($item in $Ticket.RequestedItems){
    <#
        Check ticket item
        if it's not valid then continue
    #>
    
    Update-Property -object $Ticket -propname CountOfValidAccounts # -value 1 (by default)

    $itemApprover = $adobjectHash.($item.Owner).manager
    Update-Property -object $Ticket -propname Approvers -value $itemApprover

    $itemData = $adobjectHash.($item.Owner).distinguishedname
    Update-Property -object $item -propname OwnerDN -value $itemData
}

$Ticket

$Ticket.RequestedItems | ForEach-Object {[pscustomobject] $_ }

#endregion
