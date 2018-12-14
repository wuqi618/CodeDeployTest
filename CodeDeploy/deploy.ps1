# Are you running in 32-bit mode?
#   (\SysWOW64\ = 32-bit mode)

if ($PSHOME -like "*SysWOW64*")
{
  Write-Warning "Restarting this script under 64-bit Windows PowerShell."

  # Restart this script under 64-bit Windows PowerShell.
  #   (\SysNative\ redirects to \System32\ for 64-bit mode)

  & (Join-Path ($PSHOME -replace "SysWOW64", "SysNative") powershell.exe) -File `
    (Join-Path $PSScriptRoot $MyInvocation.MyCommand) @args

  # Exit 32-bit script.

  Exit $LastExitCode
}

# Was restart successful?
Write-Warning "Hello from $PSHOME"
Write-Warning "  (\SysWOW64\ = 32-bit mode, \System32\ = 64-bit mode)"
Write-Warning "Original arguments (if any): $args"

# 64-bit script code follows here...

Import-Module WebAdministration

$iisAppName = "SimpleWebApi"
$directoryPath = "C:\inetpub\SimpleWebApi"
$runtime = ""

Function Create-ApplicationPool ($iisAppPoolName, $runtime)
{
    Set-Location IIS:\AppPools\

    Write-Host "Checking application pool: ${iisAppPoolName}" -ForegroundColor Magenta

    if (!(Test-Path $iisAppPoolName -pathType container))
    {
        Write-Host "Creating application pool: ${iisAppPoolName}" -ForegroundColor Magenta

        $appPool = New-Item $iisAppPoolName
        $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $runtime
         
        Write-Host "Application pool was successfully created!" -ForegroundColor Magenta
    }
    else
    {
        Write-Host "application pool already exists." -ForegroundColor Magenta
    }
}

Function Create-Site ($iisAppName, $directoryPath, $cert, $certLocation)
{
    Set-Location IIS:\Sites\
    $iisAppPoolName = $iisAppName
    $protocol = "http"
 
    Write-Host "Checking IIS site: ${iisAppName}" -ForegroundColor Magenta

    if (!(Test-Path $iisAppName -pathType container))
    {
        Write-Host "Creating IIS site: ${iisAppName}" -ForegroundColor Magenta

        $iisApp = New-Item $iisAppName -bindings @{protocol=$protocol;bindingInformation=":80:"}  -physicalPath $directoryPath
        $iisApp | Set-ItemProperty -Name "applicationPool"-Value $iisAppPoolName
        
        Write-Host "IIS site was successfully created!" -ForegroundColor Magenta
    }
    else
    {
        Write-Host "IIS site already exists." -ForegroundColor Magenta

        Write-Host "Updating physical path..." -ForegroundColor Magenta

        Set-ItemProperty $iisAppName -name physicalPath -value $directoryPath
    }
}

Create-ApplicationPool $iisAppName $runtime
Create-Site $iisAppName $directoryPath