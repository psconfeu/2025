
# function Get-Fruit {
#     # $result = . .\MyApi.ps1

#     $result = (Invoke-RestMethod http://localhost:666/api).result
#     Write-Output $result
# }









# Add parameter

# function Get-Fruit {
#     Param(
#         $Fruit
#     )
#     # $result = . .\MyApi.ps1

#     $result = (Invoke-RestMethod http://localhost:666/api).result

#     Write-Output $result
# }






















# Add parameter type

function Get-Fruit {
    Param(
        [string]$Fruit,
        [switch]$Icons
    )
    # $result = . .\MyApi.ps1

    $result = (Invoke-RestMethod http://localhost:666/api).result

    Write-Output $result
}
