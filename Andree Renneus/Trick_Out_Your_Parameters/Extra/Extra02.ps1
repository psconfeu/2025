<#
demo different validations and benefits / drawbacks of doing it in the parameter block vs function body.
#>

function PipelineTest {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline,Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [ValidateNotNullOrWhiteSpace()]
        # [Parameter(ValueFromPipeline)]
        # [AllowNull()]
        # [AllowEmptyString()]
        # [string]
        $InputObject
    )
    begin {
        $i = 0
    }
    process {
        $i++
        # if (-Not $InputObject) {
        #     Write-Warning "$i null/empty"
        #     return
        # }
        # if ([string]::IsNullOrWhiteSpace($InputObject)) {
        #     Write-Warning "$i null/whitespace"
        #     return
        # }
        Write-Host "PipelineTest $InputObject : $i"
    }
}

1, 2, 3, ' ', '', $null, 7 | PipelineTest #-ErrorAction Stop
