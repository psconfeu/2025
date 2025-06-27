<#
    .SYNOPSIS
    Resolves a supplied name using DNS.

    .DESCRIPTION
    Resolves a supplied name using DNS.
    This function uses dig or host

    .PARAMETER Name
    Specifies the host or domain name to resolve.

    .PARAMETER Type
    Specifies one or multiple query types.

    .PARAMETER Server
    Specifies the DNS server(s) to use. If omitted, the default servers set in the OS will be used.

    .PARAMETER RawDNSAnswers
    If specified, the function will return raw DNS reply strings.

    .PARAMETER NSLookupFallback
    If neither dig nor host are present on the machine and the switch is specified,
    the function will try to locate and use nslookup as a last resort.
    The nslookup results are not parsed but returned as-is so only suitable for
    interactive operations.

    .INPUTS
    None. You can't pipe objects to Resolve-LinuxDNSName.

    .OUTPUTS
    Array of objects representing query results.
    Array of strings representing raw query results or nslookup output.
    False, if NXDOMAIN was received from all servers.
    Null, if name resolution was not successful or command not invokable.

    .EXAMPLE
    PS> Resolve-LinuxDNSName -Name "www.google.com"
    
    Name      : www.google.com
    TTL       : 244
    Type      : A
    Section   : Answer
    IPAddress : 142.250.185.68

    .NOTES
    To do:
    - additional query types
    - timeouts
    - recursion
#>
function Resolve-LinuxDNSName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$false)]
        [ValidateSet('A','SOA','NS','MX','CNAME','TXT','SRV')]
        [string[]]$Type = @('A'),
        [Parameter(Mandatory=$false)]
        [string[]]$Server,
        [Parameter(Mandatory=$false)]
        [switch]$RawDNSAnswers,
        [Parameter(Mandatory=$false)]
        [switch]$NSLookupFallback
    )
    if (-not $IsLinux) { 
        Write-Verbose 'This command is designed to be ran on Linux'
        return $null 
    }
    $nativeCmd = $null
    if ($null -ne (Invoke-Expression -Command 'which dig 2>/dev/null')) {
        Write-Verbose 'dig found on the system.'
        $nativeCmd = 'dig'
    } elseif ($null -ne (Invoke-Expression -Command 'which host 2>/dev/null')) {
        Write-Verbose 'dig not found, but host found on the system.'
        $nativeCmd = 'host'
    } elseif ($null -ne (Invoke-Expression -Command 'which nslookup 2>/dev/null')) {
        if ($NSLookupFallback) {
            Write-Verbose 'Neither dig nor host found, but nslookup is present. Falling back to that.'
            $nativeCmd = 'nslookup'
        } else {
            Write-Verbose 'Neither dig nor host found. nslookup is present, but not falling back to that.'
        }
    } else {
        Write-Verbose 'No well-known name resolution commands found on the system.'
    }
    if ($null -eq $nativeCmd) {
        Write-Warning 'No well-known name resolution commands (dig, host) found on the system.'
        return $null
    }
    $rawResults = @()
    foreach ($queryType in $Type) {
        switch ($nativeCmd) {
            'dig' {
                $cmd = ('dig -t {0} +noall +answer {1}' -f $queryType, $Name)
                if ($Server.Count -eq 0) {
                    Write-Verbose ('Running command: {0}' -f $cmd)
                    $rawResults += (Invoke-Expression -Command $cmd)
                } else {
                    foreach ($srv in $Server) {
                        $cmdx = ('{0} @{1}' -f $cmd, $srv)
                        Write-Verbose ('Running command: {0}' -f $cmdx)
                        $rawResults += (Invoke-Expression -Command $cmdx)
                    }
                }
            }
            'host' {
                $cmd = ('host -v -t {0} {1}' -f $queryType, $Name)
                if ($Server.Count -eq 0) {
                    Write-Verbose ('Running command: {0}' -f $cmd)
                    $expResult = (Invoke-Expression -Command ('{0} 2>&1' -f $cmd))
                    $isAnswer = $false
                    foreach ($line in $expResult) {
                        if ([string]::IsNullOrWhiteSpace($line)) {
                            $isAnswer = $false
                        }
                        if ($isAnswer) {
                            $rawResults += $line
                        }
                        if ($line -match '\;\;\s+ANSWER\sSECTION\:') {
                            $isAnswer = $true
                        }
                    }
                } else {
                    foreach ($srv in $Server) {
                        $cmdx = ('{0} {1}' -f $cmd, $srv)
                        Write-Verbose ('Running command: {0}' -f $cmdx)
                        $expResult = (Invoke-Expression -Command ('{0} 2>&1' -f $cmdx))
                        $isAnswer = $false
                        foreach ($line in $expResult) {
                            if ($isAnswer) {
                                $rawResults += $line
                            }
                            if ($line -match '\;\;\s+ANSWER\sSECTION\:') {
                                $isAnswer = $true
                            }
                        }
                    }
                }
            }
            'nslookup' {
                $cmd = ('nslookup -query={0} {1}' -f $queryType, $Name)
                if ($Server.Count -eq 0) {
                    Write-Verbose ('Running command: {0}' -f $cmd)
                    $rawResults += (Invoke-Expression -Command $cmd)
                } else {
                    foreach ($srv in $Server) {
                        $cmdx = ('{0} {1}' -f $cmd, $srv)
                        Write-Verbose ('Running command: {0}' -f $cmdx)
                        $rawResults += (Invoke-Expression -Command $cmdx)
                    }
                }
            }
        }
    }
    if ($RawDNSAnswers -or ($nativeCmd -eq 'nslookup')) {
        $result = ($rawResults | Select-Object -Unique)
    } else {
        $result = @()
        foreach ($res in ($rawResults | Select-Object -Unique)) {
            if ($res -match '^(?<dom>\S+)\.\s+(?<ttl>\d+)\s+IN\s+(?<rtype>\S+)\s+(?<data>.*)$') {
                $resObj = [PSCustomObject]@{
                    'Name' = $Matches['dom']
                    'TTL' = $Matches['ttl']
                    'Type' = $Matches['rtype']
                    'Section' = 'Answer'
                }
                switch ($Matches['rtype']) {
                    'A' {
                        $resObj | Add-Member -MemberType NoteProperty -Name 'IPAddress' -Value $Matches['Data']
                    }
                    'NS' {
                        $resObj | Add-Member -MemberType NoteProperty -Name 'NameHost' -Value $Matches['Data']
                    }
                    'CNAME' {
                        $resObj | Add-Member -MemberType NoteProperty -Name 'NameHost' -Value $Matches['Data']
                    }
                    'TXT' {
                        $resObj | Add-Member -MemberType NoteProperty -Name 'Strings' -Value ($Matches['Data']).Trim('\"').Split('","')
                    }
                    'MX' {
                        $dataFields = ($Matches['Data'] -split ' ')
                        $resObj | Add-Member -MemberType NoteProperty -Name 'NameExchange' -Value $dataFields[1]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'Preference' -Value $dataFields[0]
                    }
                    'SOA' {
                        $dataFields = ($Matches['Data'] -split ' ')
                        $resObj | Add-Member -MemberType NoteProperty -Name 'PrimaryServer' -Value $dataFields[0]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'NameAdministrator' -Value $dataFields[1]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'SerialNumber' -Value $dataFields[2]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'TimeToZoneRefresh' -Value $dataFields[3]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'TimeToZoneFailureRetry' -Value $dataFields[4]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'TimeToExpiration' -Value $dataFields[5]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'DefaultTTL' -Value $dataFields[6]
                    }
                    'SRV' {
                        $dataFields = ($Matches['Data'] -split ' ')
                        $resObj | Add-Member -MemberType NoteProperty -Name 'Priority' -Value $dataFields[0]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'Weight' -Value $dataFields[1]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'Port' -Value $dataFields[2]
                        $resObj | Add-Member -MemberType NoteProperty -Name 'Target' -Value $dataFields[3]
                    }
                }
                $result += $resObj
            } else {
                Write-Warning ('Could not parse response: {0}' -f $res)
            }
        }
    }
    return $result
}