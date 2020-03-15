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
$Tm1MailSubject = "[ALERT] - Tm1Monitoring - An issue occurred with Tm1 Web"

$Tm1WebUri = "http://localhost:9510/tm1web/"
$Tm1WebTimeoutSec = 5

$Tm1SendAlerte = $false
try {
    $Tm1WebResponse = Invoke-WebRequest -Uri $Tm1WebUri -TimeoutSec $Tm1WebTimeoutSec
    If($Tm1WebResponse.StatusCode -ne 200){
        $Tm1SendAlerte = $true
    }
    if($Tm1SendAlerte){
        $Tm1MailBodyAsHtml = $false
        $Tm1MailBody = "Access to the Tm1web ($Tm1WebUri) returned an error status ($($Tm1WebResponse.StatusCode))."
    }
}

catch {
    $Tm1SendAlerte = $true
    $Tm1MailBodyAsHtml = $false
    if($_.Exception.CancellationToken.IsCancellationRequested){
        $Tm1MailBody = "Access to the Tm1web ($Tm1WebUri) exceeds the tolerated waiting time ($Tm1WebTimeoutSec s)."
    }
    else{
        $Tm1MailBody = "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
    }
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