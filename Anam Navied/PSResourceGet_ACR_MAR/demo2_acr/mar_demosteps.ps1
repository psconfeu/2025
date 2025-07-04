# Registry the MAR repository
Register-PSResourceRepository -Name MAR -Uri "https://mcr.microsoft.com" -ApiVersion ContainerRegistry -Trusted

# Find a resource:
Find-PSResource "Az.Compute" -Repository MAR

# Install a resource:
Install-PSResource "Az.Compute" -Repository MAR -PassThru