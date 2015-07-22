# Powershell script for working with Gnip's Historical Powertrack service
# http://support.gnip.com/apis/historical_api/

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$command,
    
    [string]$jobid,
    [string]$file
)

$help = @"
USAGE:
    .\gnip-historical-powertrack.ps1 <command> <options>

AVAILABLE COMMANDS:
    ... list-jobs
    ... list-job -jobid <jobid>
    ... request-job -file <filename>
    ... accept-job -jobid <jobid>
    ... reject-job -jobid <jobid>
    ... download-files -jobid <jobid>

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

    Function ListJobs {
        $response = Invoke-RestMethod -Method Get -Uri "https://historical.gnip.com/accounts/$account/jobs.json" `
           -Headers $headers -ContentType "application/json"
        echo $response.jobs
    }

    Function ListJob($jobid) {
        $response = Invoke-RestMethod -Method Get -Uri "https://historical.gnip.com/accounts/$account/jobs/$jobid.json" `
           -Headers $headers -ContentType "application/json"
        echo $response
    }

    Function RequestJob($file) {
        try {
            $response = Invoke-RestMethod -Method POST -Uri "https://historical.gnip.com/accounts/$account/jobs.json" `
               -Headers $headers -ContentType "application/json" -InFile $file
        } catch {
            $response = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($response)
            echo $reader.ReadToEnd()
        }
    }

    Function AcceptJob($jobid) {
        $response = Invoke-RestMethod -Method PUT -Uri "https://historical.gnip.com/accounts/$account/publishers/twitter/historical/track/jobs/$jobid.json" `
           -Headers $headers -ContentType "application/json" -Body "{ ""status"": ""accept"" }"
        echo $response
    }

    Function RejectJob($jobid) {
        $response = Invoke-RestMethod -Method PUT -Uri "https://historical.gnip.com/accounts/$account/publishers/twitter/historical/track/jobs/$jobid.json" `
           -Headers $headers -ContentType "application/json" -Body "{ ""status"": ""reject"" }"
        echo $response
    }

    Function DownloadFiles($jobid) {
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")        
        $jsonserial= New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer 
        $jsonserial.MaxJsonLength  = 10000000
        $responseRaw = Invoke-WebRequest -Method Get -Uri "https://historical.gnip.com/accounts/$account/publishers/twitter/historical/track/jobs/$jobid/results.json" `
            -Headers $headers -ContentType "application/json"
        $response = $jsonserial.DeserializeObject($responseRaw.Content)

        echo "Job contains $($response.urlCount) files with total size of $([math]::Round($response.totalFileSizeBytes / 1024 / 1024, 2)) MB"

        $outputFolder = "jobfiles-$jobid-$(Get-Date -Format yyyy-MM-dd)"
        New-Item -ItemType directory -Path $outputFolder -Force | Out-Null

        foreach ($url in $response.urlList) {
            $abspath = ([System.URI]$url).AbsolutePath
            $split = $abspath.LastIndexOf("/")
            $filepath = $abspath.Substring(0, $split)
            $filename = $abspath.Substring($split + 1)

            $destdir = "$outputFolder$filepath"
            $destpath = "$destdir/$filename"

            if (!(Test-Path -Path $destdir)) {
                New-Item -ItemType directory -Path $destdir -Force | Out-Null
            }

            if (!(Test-Path -Path $destpath)) {
                echo "Downloading file to $destpath"
                Invoke-WebRequest -Uri $url -OutFile $destpath
            }
        }
    }
}

switch ($command)
{
    "list-jobs" { $powertrack.ListJobs() }
    "list-job" { $powertrack.ListJob($jobid) }
    "request-job" { $powertrack.RequestJob($file) }
    "accept-job" { $powertrack.AcceptJob($jobid) }
    "reject-job" { $powertrack.RejectJob($jobid) }
    "download-files" { $powertrack.DownloadFiles($jobid) }

    default { echo $help }
}
