# Powershell script for working with Gnip's Historical Powertrack service
# http://support.gnip.com/apis/historical_api/

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$command
)

$help = @"
USAGE:
    .\gnip-powertrack.ps1 <command> <options>

AVAILABLE COMMANDS:
    ... get-rules

CONFIGURATION:
    Make sure there is an authorization.txt file in this directory with one line that has
    your gnip username & password in the format username:password.

    Also create an accounts.txt file which contains your account name for Gnip.

"@

$powertrack = New-Module -AsCustomObject -ScriptBlock `
{
    [String] $account = `
        [IO.File]::ReadAllText((Get-Item account.txt | Resolve-Path).ProviderPath).Trim()
    
    [Hashtable] $headers = @{
        Authorization = "Basic " + [System.Convert]::ToBase64String(
            [System.Text.Encoding]::ASCII.GetBytes(
                [IO.File]::ReadAllText((Get-Item authorization.txt | Resolve-Path).ProviderPath).Trim()
            )
        )
    }

    Function GetRules {
        $response = Invoke-RestMethod -Method Get -Uri "https://api.gnip.com:443/accounts/$account/publishers/twitter/streams/track/Production/rules.json" `
           -Headers $headers -ContentType "application/json"
        echo $response
    }
}

switch ($command)
{
    "get-rules" { $powertrack.GetRules() }

    default { echo $help }
}
