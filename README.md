## Powershell script for Gnip's Historical Powertrack API

### Configuration

Copy the sample `account.txt` and `authorization.txt` files and add your
personal information.

### Running

reference: http://support.gnip.com/apis/historical_api/

Samples:

```
.\gnip-historical-powertrack.ps1 help
.\gnip-historical-powertrack.ps1 request-job -file <file>
.\gnip-historical-powertrack.ps1 list-jobs
.\gnip-historical-powertrack.ps1 accept-job -jobid <jobid>
.\gnip-historical-powertrack.ps1 download-files -jobid <jobid>
```
