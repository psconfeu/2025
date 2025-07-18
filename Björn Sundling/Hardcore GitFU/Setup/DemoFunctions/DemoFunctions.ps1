function FruitAPI {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseBOMForUnicodeEncodedFile", "")]
    param (
        [switch]$Icons,
        $Auth
    )
        
    if ($Icons) {
        @('🍎', '🍌', '🥝')
    }
    else {
        @('Apple', 'Banana', 'Kiwi')
    }
}

    
function Invoke-FruitAPI {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding()]
    param (
        $Secret = 'SuperSecretPassword',
        [switch]$Icons
    )
    
    $Auth = ConvertTo-SecureString -String $Secret -AsPlainText -Force
    
    # Find the bug!
    FruitAPI -Auth $Auth -Icons:$Icons
}





# Oh, look, A spelling error! Might just fix this right away!
<#
.SYNOPSIS
    Gtest fruit by ghetting the frit APIII
#>
function Get-Fruit {
    param (
        [switch]$Icons
    )

    # Add some code...
    # Invoke-FruitAPI -Icons:$Icons
}