$Sleep = (Get-Random -Minimum 0 -Maximum 500)
Start-Sleep -Milliseconds $Sleep


if ((Get-Random -Minimum 0 -Maximum 10) -gt 5)
{
    throw "No good!"
}