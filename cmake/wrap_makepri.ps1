# Wrapper to deal w/ makepri.exe outputting raw UTF-16
# https://github.com/PowerShell/PowerShell/discussions/17163
$origEncoding = [Console]::OutputEncoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $output = ( & "$($args[0])" $args[1..($args.Count-1)] 2>&1 ) # FIXME: 2>&1 seems to add some weirdness ('System.Management.Automation.RemoteException' outputs)
}
finally {
    [Console]::OutputEncoding = $origEncoding
}
# Just 'Write-Host $x' formats weirdly
foreach($x in $output)
{
    Write-Host $x
}
