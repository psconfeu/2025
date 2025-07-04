            . C:\Users\annavied\Documents\demo_resources\scenario3_moduleDotSourceWildcard\DotSourceFileNoWildCard_System32.ps1
            function PublicFnA { "PublicFnA"; PublicDSFnA }
            function PrivateFnA { "PrivateFnA"; PrivateDSFnA }

            Export-ModuleMember -Function "*"
