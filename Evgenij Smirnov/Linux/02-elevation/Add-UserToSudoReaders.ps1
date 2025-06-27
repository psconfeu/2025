if (-not [System.Environment]::IsPrivilegedProcess) {
    Write-Warning 'Please run me elevated!'
    exit
}
Write-Host "UserName in Env: $([System.Environment]::UserName)"
Write-Host "UserName in Var: $($env:USERNAME)"
$sudoersFile = '/etc/sudoers.d/90-psconf-admins'
Invoke-Expression ('touch {0}' -f $sudoersFile)
$sudoersContent = @(
    '# Admins able to perform tasks with no password'
    '# Created by script '
    ('{0} ALL=(ALL) NOPASSWD: {1} /etc/sudoers' -f "cj_berlin", (Invoke-Expression -Command 'which cat'))
)
$sudoersContent | Set-Content -Path $sudoersFile -Force -Encoding UTF8
Invoke-Expression ('chmod 440 {0}' -f $sudoersFile)