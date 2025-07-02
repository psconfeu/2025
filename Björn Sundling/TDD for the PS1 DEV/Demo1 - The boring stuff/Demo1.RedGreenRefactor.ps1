
# Step 1 - Just go green

# function Get-Fruit {
#     Write-Output 'Banana'
# }










# Step 1.2 - Just go green - With a bit of refactoring

# function Get-Fruit {
#     . .\MyApi.ps1
#     (Invoke-RestMethod http://localhost:666/api).result
# }










# Step 1.3 - Just go green - With a bit more refactoring

function Get-Fruit {
    # $result = . .\MyApi.ps1

    $result = (Invoke-RestMethod http://localhost:666/api).result
    Write-Output $result
}