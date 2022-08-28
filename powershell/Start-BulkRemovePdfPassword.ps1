# Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Assembly System.Drawing

###########################
######## FUNCTION #########
###########################
function Write-Log {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [String]$Message,
        [ValidateNotNullOrEmpty()]
        [string[]]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content "$PSScriptRoot\debug.log" "$timestamp | $Level | $Message"

    if ($Level -eq "SUCCESS") {
        Add-Content "$PSScriptRoot\files-uncrypted.log" "$timestamp | $($Message -replace ' : file unprotected','')"
        $logsLevelColor = "green"
    }
    elseif ($Level -eq "ERROR") { $logsLevelColor = "red" }
    elseif ($Level -eq "WARNING") { $logsLevelColor = "yellow" }
    else { $logsLevelColor = "white" }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $logsLevelColor
}

Function Open-FolderDialog {
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.RootFolder = 'MyComputer'
    [void] $FolderBrowserDialog.ShowDialog()
    return "$($FolderBrowserDialog.SelectedPath)"
}

function Get-QpdfLastRelease {
    $Label3.Text = "Downloading last QPDF release from Github repo ..."
    $Release = (Invoke-WebRequest -UseBasicParsing "https://github.com/qpdf/qpdf/releases/latest").Links.href | Where-Object { $_ -like "*mingw64*" }
    Invoke-WebRequest -UseBasicParsing "https://github.com/$Release"  -OutFile "qpdf.zip" -ErrorAction Stop
    Expand-Archive "qpdf.zip" -DestinationPath $PSScriptRoot -ErrorAction Stop
    Remove-Item "qpdf.zip"
    Write-Log "qPDF as been downloaded and extracted"
}

function Get-QpdfExeFilePath {
    try { (Get-ChildItem -Path $PSScriptRoot -File -Recurse -Filter "qpdf.exe")[0].FullName }
    catch { $r = $null }
    return $r
}

$StartProcessing = {
    Write-Log "PDF Password Remover : Started"

    # Try to found qPDF exe (if not > download from github repo)
    if ((Get-QpdfExeFilePath).Count -eq 0) { Get-QpdfLastRelease }
    $qpdfExe = Get-QpdfExeFilePath
    Write-Log "qPDF exe detection : $qpdfExe" -Level "DEBUG"

    if ($CheckBox1.Checked) { Write-Log "User choice : overwrite existing file with unprotected one" }
    else { Write-Log "User choice : create new pdf file if unprotected" }

    $Button1.Enabled = 0
    $Button1.Text = "Searching"
    $Button2.Enabled = 0
    $Form.ClientSize = (New-Object -TypeName System.Drawing.Size(400, 290))

    try {
        $passwords = $TextBox2.Text -split ","
        try { $pdfFiles = Get-ChildItem -Path "$($TextBox1.Text)" -File -Recurse -Filter "*.pdf" -Exclude "*.decrypted.pdf" -ErrorAction SilentlyContinue}
        Catch { [void][System.Windows.Forms.MessageBox]::Show("$($_.Exception.ErrorRecord.Exception.Message)", "Erreur") }
        $Button1.Text = "Processing"
        Write-Log "$($pdfFiles.Count) pdf's files discover in $($TextBox1.Text)"
        $ProgressBar1.Value = 0
        $ProgressBar1.Maximum = $pdfFiles.Count

        $pdfFiles | % {
            $pdfFile = $_.FullName
            $Label3.Text = "Processing $pdfFile"
            
            # Check if pdf is protected
            # Write-Log "$qpdfExe --requires-password `"$pdfFile`"" -Level "DEBUG"
            if ((Start-Process "$qpdfExe" -ArgumentList "--requires-password `"$pdfFile`"" -NoNewWindow -PassThru -Wait).ExitCode -eq 0) {
                # Try every password
                $pwdFound = 0
                foreach ($pwd in $passwords) {
                    if ($pwdFound -eq 1) { continue }
                    
                    # & "$qpdfExe" "C:\Users\Thomas\Downloads\test\fichier crypted.pdf" --decrypt --verbose --password=0 "C:\Users\Thomas\Downloads\test\fichier uncrypted.pdf"
                    if ((Start-Process "$qpdfExe" -ArgumentList "--verbose --requires-password --password=$pwd `"$pdfFile`"" -NoNewWindow -PassThru -Wait).ExitCode -eq 3) {
                        $pwdFound = 1

                        # Remove password from pdf file
                        if ($CheckBox1.Checked) { $cmd = Start-Process "$qpdfExe" -ArgumentList "--verbose --decrypt --password=$pwd --replace-input `"$pdfFile`"" -NoNewWindow -PassThru -Wait }
                        else {
                            $cmd = Start-Process "$qpdfExe" -ArgumentList "--verbose --decrypt --password=$pwd `"$pdfFile`" `"$($pdfFile).decrypted.pdf`"" -NoNewWindow -PassThru -Wait                                                                               
                        }

                        # Check Exit Status
                        if ($cmd.ExitCode -eq 0) { Write-Log "$pdfFile : file unprotected" -Level "SUCCESS" }
                        elseif ($cmd.ExitCode -eq 2) { Write-Log "$pdfFile : errors occurred" -Level "ERROR" }
                        elseif ($cmd.ExitCode -eq 3) { Write-Log "$pdfFile : warning were flagged by qPDF" -Level "WARNING" }
                    } 
                    elseif (($pwd -eq $passwords[-1]) -and ($pwdFound -eq 0)) { Write-Log "$pdfFile : all passwords failed" -Level "ERROR" }
                }   
            }
            else { Write-Log "$pdfFile : isn't password protected" -Level "DEBUG" }
            $ProgressBar1.PerformStep()
        }
    }
    catch { [void][System.Windows.Forms.MessageBox]::Show("$($_.Exception.ErrorRecord.Exception.Message)", "Erreur") }

    $Button1.Text = "End"
    $Button2.Enabled = 1
    Write-Log "PDF Password Remover : Ended"
}

$UnlockStartButton = {
    $Button1.Text = 'Start'
    # Turn Start Button On
    if (($TextBox1.Text -ne "") -and ($TextBox2.Text -ne "") ) { $Button1.Enabled = 1 }
    else { $Button1.Enabled = 0 }
}
###########################
########### GUI ###########
###########################

#Button1
$Button1 = (New-Object -TypeName System.Windows.Forms.Button)
$Button1.Location = (New-Object -TypeName System.Drawing.Point(20, 165))
$Button1.Size = (New-Object -TypeName System.Drawing.Size(160, 35))
$Button1.Text = 'Start'
$Button1.Enabled = 0
$Button1.add_Click(
    $StartProcessing
)

#Button2
$Button2 = (New-Object -TypeName System.Windows.Forms.Button)
$Button2.Location = (New-Object -TypeName System.Drawing.Point(220, 165))
$Button2.Size = (New-Object -TypeName System.Drawing.Size(160, 35))
$Button2.Text = 'Close'
$Button2.add_Click({ $Form.Dispose() })

#CheckBox1
$CheckBox1 = (New-Object -TypeName System.Windows.Forms.CheckBox)
$CheckBox1.Location = (New-Object -TypeName System.Drawing.Point(20, 130))
$CheckBox1.Size = (New-Object -TypeName System.Drawing.Size(360, 20))
$CheckBox1.Text = 'Overwrite protected PDF with unprotected one'
$CheckBox1.Checked = 1

#Label1
$Label1 = (New-Object -TypeName System.Windows.Forms.Label)
$Label1.Location = (New-Object -TypeName System.Drawing.Point(20, 20))
$Label1.Size = (New-Object -TypeName System.Drawing.Size(360, 20))
$Label1.Text = 'Choose folder where PDF files are stored :'
$Label1.TextAlign = 'MiddleLeft'

#Label2
$Label2 = (New-Object -TypeName System.Windows.Forms.Label)
$Label2.Location = (New-Object -TypeName System.Drawing.Point(20, 80))
$Label2.Size = (New-Object -TypeName System.Drawing.Size(360, 20))
$Label2.Text = 'List of passwords to try (comma separated)'
$Label2.TextAlign = 'MiddleLeft'

#Label3
$Label3 = (New-Object -TypeName System.Windows.Forms.Label)
$Label3.Location = (New-Object -TypeName System.Drawing.Point(20, 250))
$Label3.Size = (New-Object -TypeName System.Drawing.Size(310, 30))
$Label3.TextAlign = 'MiddleLeft'

#TextBox1
$TextBox1 = (New-Object -TypeName System.Windows.Forms.TextBox)
$TextBox1.Location = (New-Object -TypeName System.Drawing.Point(20, 40))
$TextBox1.Size = (New-Object -TypeName System.Drawing.Size(360, 21))
$TextBox1.add_TextChanged( $UnlockStartButton )
$TextBox1.Add_Click({ $TextBox1.Text = Open-FolderDialog })

#TextBox2
$TextBox2 = (New-Object -TypeName System.Windows.Forms.TextBox)
$TextBox2.Location = (New-Object -TypeName System.Drawing.Point(20, 100))
$TextBox2.Size = (New-Object -TypeName System.Drawing.Size(360, 21))
$TextBox2.add_TextChanged( $UnlockStartButton )

#ProgressBar1
$ProgressBar1 = New-Object System.Windows.Forms.ProgressBar
$ProgressBar1.Location = New-Object System.Drawing.Point(20, 210)
$ProgressBar1.Size = New-Object System.Drawing.Size(360, 30)
$ProgressBar1.Step = 1
$ProgressBar1.Value = 0

#Form
$Form = New-Object -TypeName System.Windows.Forms.Form
$Form.ClientSize = (New-Object -TypeName System.Drawing.Size(400, 210))
$Form.Controls.AddRange(@($Button1, $Button2, $Label1, $Label2, $Label3, $CheckBox1, $TextBox1, $TextBox2, $ProgressBar1))
$Form.Text = 'Unprotect multiple PDF files'
$Form.StartPosition = 'CenterScreen'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
#$Form.TopMost = $true
$Form.ShowDialog()
