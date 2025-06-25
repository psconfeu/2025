# Instructions

## Prerequisites for leveraging Polyglot Notebooks

To open and run the Polyglot Notebook files (`.dib`) in this demo folder, you'll need the following:

### Required Software

1. **Visual Studio Code**
   - Download and install from [https://code.visualstudio.com/](https://code.visualstudio.com/)

2. **Polyglot Notebooks Extension**
   - Install the "Polyglot Notebooks" extension from the VS Code Extensions marketplace
   - Extension ID: `ms-dotnettools.dotnet-interactive-vscode`
   - This extension enables support for `.dib` files and interactive notebooks

3. **.NET SDK** (Required for Polyglot Notebooks)
   - Install .NET 8.0 SDK or later from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download)
   - Verify installation by running `dotnet --version` in terminal

### PowerShell Requirements

1. **PowerShell 7.x**
   - Install PowerShell 7.4 or later from [https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases)
   - Or install via winget: `winget install Microsoft.PowerShell`

2. **Required PowerShell Modules**

   ```powershell
   # Install Azure PowerShell modules
   Install-Module -Name Az -Scope CurrentUser -Force

   # Install Dev Box and Azure Deployment Environments modules
   Install-Module -Name Az.DevCenter -Scope CurrentUser -Force
   Install-Module -Name Az.Resources -Scope CurrentUser -Force

   # Install additional modules for demos
   Install-Module -Name PSDesiredStateConfiguration -Scope CurrentUser -Force
   Install-Module -Name Microsoft.WinGet.Client -Scope CurrentUser -Force
   ```

### Azure Prerequisites

1. **Azure Account**
   - Active Azure subscription
   - Appropriate permissions to create and manage:
     - Azure Dev Box resources
     - Azure Deployment Environments
     - Resource groups and deployments

2. **Azure CLI** (Optional but recommended)
   - Install from [https://learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli)
   - Or install via winget: `winget install Microsoft.AzureCLI`

### Development Environment Setup

1. **Dev Box Prerequisites**
   - Access to an Azure Dev Center
   - Dev Box project permissions
   - Understanding of Dev Box pools and definitions

2. **Azure Deployment Environments Prerequisites**
   - Access to Azure Deployment Environments
   - Catalog and environment type configurations
   - ARM/Bicep template knowledge (helpful)

### Getting Started

1. Open VS Code in this folder
2. Install the required extensions and dependencies listed above
3. Open any `.dib` file to start with the interactive notebooks
4. Run the setup cells to authenticate with Azure and prepare your environment

### Demo Files

- `0 - Intro.dib` - Introduction and environment setup
- `1 - DSC.dib` - Desired State Configuration demonstrations
- `2 - WinGet.dib` - Windows Package Manager integration examples
- `3 - DevBox.dib` - Microsoft Dev Box features and management
- `4 - ADE.dib` - Azure Deployment Environments workflows
- `5 - Extras.dib` - Additional features and advanced scenarios

### Additional Resources

- `examples/` - Sample configurations and templates
- `user-customizations/` - Customization examples for Dev Box environments