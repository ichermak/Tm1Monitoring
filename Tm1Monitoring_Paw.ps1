$Tm1MailConfigPath = "$PSScriptRoot\MailConfig.JSON"
$Tm1MailFrom = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).from
$Tm1MailTo = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).to
$Tm1MailPriority = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).priority
$Tm1MailSmtpServer = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).smtpserver
$Tm1MailPort = [int](Get-Content $Tm1MailConfigPath | ConvertFrom-Json).port
$Tm1MailUseSsl = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).usessl | % {if($_ -eq "True"){$true} else{$false}}
$Tm1MailUser = (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).user
$Tm1MailPassword = ConvertTo-SecureString (Get-Content $Tm1MailConfigPath | ConvertFrom-Json).password -AsPlainText -Force 
$Tm1MailCredential = New-Object System.Management.Automation.PSCredential ($Tm1MailUser, $Tm1MailPassword)
$Tm1MailSubject = "[ALERT] - Tm1Monitoring - An issue occurred with Planning Analytics Workspace"

$Tm1SendAlerte = $false
try {
    $Tm1PawContainersToSkip = @("bss-init")
    $Tm1PawContainers = docker container ls --all --format='{{json .}}'
    foreach ($Tm1PawContainer in $Tm1PawContainers) {
        $Tm1PawContainer = $Tm1PawContainer | ConvertFrom-Json
        if($Tm1PawContainer.Image -like "*planninganalytics*"){
            if( ($Tm1PawContainer.Status -notlike "Up*") -and -not($Tm1PawContainersToSkip -contains $Tm1PawContainer.Names) ){
                $Tm1SendAlerte = $true
                $Tm1MailSubBody01 = "
                    $Tm1MailSubBody01 
                    <tr>
                        <td> $($Tm1PawContainer.Names) </td>
                        <td> $($Tm1PawContainer.Status) </td>
                    </tr>
                    "
            }
        }
    }

    if($Tm1SendAlerte){
        $Tm1MailBodyAsHtml = $true
        $Tm1MailBody = "
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset='utf-8' />
                <style>
                    table
                    {
                        border-collapse: collapse;
                    }
                    td, th
                    {
                        border: 1px solid black;
                    }
                </style>
            </head>
            <body>
                <p>
                    The following issues have occurred:<br/>
                </p>
                <table>
                    <thead>
                        <tr>
                            <th> Container Name </th>
                            <th> Container Status </th>
                        </tr>
                    </thead>
                    <tbody>
                        $Tm1MailSubBody01
                    </tbody>
                </table>
            </body>
            "
    }
}

catch {
    $Tm1SendAlerte = $true
    $Tm1MailBodyAsHtml = $false
    $Tm1MailBody = "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
    Write-Error "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
}

finally{
    If($Tm1SendAlerte){
        $Tm1Params = @{
            From = $Tm1MailFrom
            To = $Tm1MailTo
            Subject = $Tm1MailSubject
            Priority = $Tm1MailPriority
            Body = $Tm1MailBody
            BodyAsHtml = $Tm1MailBodyAsHtml
            SmtpServer = $Tm1MailSmtpServer
            Port = $Tm1MailPort
            UseSsl = $Tm1MailUseSsl
            Credential = $Tm1MailCredential
        }
        Send-MailMessage @Tm1Params
    }
}