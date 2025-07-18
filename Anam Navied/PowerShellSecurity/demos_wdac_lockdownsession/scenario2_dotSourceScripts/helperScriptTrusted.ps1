function HelperFn1
{
    param( [string] $source )
    [System.Console]::WriteLine("This can only run in FullLanguage mode")
    Add-Type -AssemblyName $source -PassThru
}
