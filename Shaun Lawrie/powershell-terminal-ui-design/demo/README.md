# PwshSpectreConsole Demo

This demo will showcase how easy it can be to create beautiful, interactive console applications using the PwshSpectreConsole module in PowerShell.

## Demo Overview

> **Scenario**  
> We're going to take docker, a common command line tool and automate some of the tasks we may like to help others with.
> We can start with building a small wizard using Spectre Console widgets.  
> Then we can build some more advanced TUI features with Spectre Console layouts and live rendering.

1. Writing a fancy header.
2. Selecting an action with `Read-SpectreSelection` that returns complex objects.
3. List container details with `Format-SpectreTable`.
4. Start and stop containers with `Read-SpectreMultiSelection` and wait for their execution with `Invoke-SpectreCommandWithStatus`.
5. Tail container logs with layouts via `New-SpectreLayout`, live updating with `Invoke-SpectreLive`, and using `Get-SpectreLayoutSizes` to fit dynamic content to layout panels.

## Closing

What we've missed, charts, trees, grids, etc. there is much more to look at, check it out for yourself and reach out if you have questions!