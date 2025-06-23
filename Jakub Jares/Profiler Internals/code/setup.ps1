if (-not (Test-Path x:\)) { 
    subst x: $PSScriptRoot
}

cd x:
cls

$function:global:prompt = { "$pwd> " }