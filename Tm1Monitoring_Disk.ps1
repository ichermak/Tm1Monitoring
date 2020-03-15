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
$Tm1MailSubject = "[ALERT] - Tm1Monitoring - An issue occurred with the disk use"

$Tm1DiskId = 'C:'
$Tm1DiskThreshold = 20/100

$Tm1SendAlerte = $false
try {
    $Tm1DiskInfo = Get-CimInstance -ClassName Win32_logicaldisk -Filter "DeviceID='$Tm1DiskId'"
    $Tm1DiskFreeSpaceRate = $Tm1DiskInfo.FreeSpace / $Tm1DiskInfo.size
    if($Tm1DiskFreeSpaceRate -lt $Tm1DiskThreshold){
        $Tm1SendAlerte = $true
    }
    if($Tm1SendAlerte) {
        $Tm1MailBodyAsHtml = $false
        $Tm1MailBody = "Free disk ($Tm1DiskId) rate ($($Tm1DiskFreeSpaceRate.tostring('P'))) is below the tolerated threshold ($($Tm1DiskThreshold.tostring('P')))."
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