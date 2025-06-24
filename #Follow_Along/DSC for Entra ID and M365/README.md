# Configuring Azure Entra ID and M365 with DSC

## Abstract

Ever dreamed to manage your Azure tenant from code?
Or maybe you've looked into Microsoft365DSC and saw how it can export live configurations but you wonder how to remediate?

Follow us while we go a few steps further by managing the configurations from code through a release and deployment pipeline.
In this session you'll get to use Microsoft365DSC in tandem with the Microsoft365DscWorkshop to bring Azure tenant configurations under source control.
With a fully automated project template setup, you'll be ready to manage your tenants efficiently by the end of the follow-along!

In this session we'll quickly review the “release pipeline model” and how to make changes to your Azure environment as a team in a secure, safe, automated, transparent and self-documenting way!
We will cover how to promote your change through the rings of Dev, Test and Prod while keeping them in sync. This concept scales from 2 to as many tenants as you'd like.

We'll start with exporting the running configuration, which is usually the first step before getting it under control from in an Infrastructure as code (IaC) approach, and follow with making changes to our live environements.

In this session you will discover how to use tools such as Azure DevOps release pipelines, DSC and Microsoft365DSC, Pester, PSScriptAnalyzer, to build your M365 and Azure management solution.

## Prerequisites
- Basic knowledge of PowerShell.
- You need a Windows machine to compile the DSC configuration.
- Clone the repo to your machine: https://github.com/raandree/Microsoft365DscWorkshop.git.
- Run the build script `.\build.ps1 -ResolveDependency -UseModuleFast`.
