using namespace System.Management.Automation

class PSConfEuTransformationAttribute : ArgumentTransformationAttribute {
    [object] Transform(
        [EngineIntrinsics] $engineIntrinsics,
        [object] $inputObject
    ) {
        $year = (Get-Date).Year
        if ($InputObject -match "\sPSConfEu\s$year$") {
            return $inputObject
        }
        if ($InputObject -match '\sPSConfEu\s\d{4}$') {
            $inputObject = $inputObject -replace '\sPSConfEu\s\d{4}$'
        }
        return $inputObject + " PSConfEu $year"
    }
}
function Test-PSConfEUTransform {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidatePattern('\sPSConfEu\s2025$')]
        [PSConfEuTransformation()]
        [string] $test
    )
    process {
        $test
    }
}


Test-PSConfEUTransform 'hello'
Test-PSConfEUTransform 'hello world' | Test-PSConfEUTransform
Test-PSConfEUTransform 'hello PSConfEu 2020'
