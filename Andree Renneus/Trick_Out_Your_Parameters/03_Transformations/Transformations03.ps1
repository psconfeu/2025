using namespace System.Management.Automation


class CommandInfoTransformAttribute : ArgumentTransformationAttribute {
    [object] Transform(
        [EngineIntrinsics] $engineIntrinsics,
        [object] $inputObject
    ) {

        if ($inputObject -isnot [CommandInfo]) {
            $inputObject = Get-Command "$inputObject" | Select-Object -First 1
        }

        if ($inputObject -is [AliasInfo]) {
            $inputObject = $inputObject.ResolvedCommand
        }

        return $inputObject
    }
}
function Show-Command {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [CommandInfoTransform()]
        [CommandInfo] $cmd
    )
    process {
        $cmd
    }
}
Show-Command ls

'ls' | Show-Command
Get-Command Get-ChildItem | Show-Command
