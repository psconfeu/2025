# Creating and using COM objects are not allowed - can expose Win32 APIs that have likely never been rigorously hardened as part of an attack surface.

New-Object -ComObject Scripting.FileSystemObject

# The New-Object cmdlet is also only allowed on approved types.
New-Object -TypeName System.Version -ArgumentList "1.2.3.4"