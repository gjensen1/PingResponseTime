


# -----------------------
# Define Global Variables
# -----------------------
$Global:Folder = $env:USERPROFILE+"\Documents\PingResponse"

#*************************************************
# Check for Folder Structure if not present create
#*************************************************
Function Verify-Folders {
    [CmdletBinding()]
    Param()
    "Building Local folder structure" 
    If (!(Test-Path $Global:Folder)) {
        New-Item $Global:Folder -type Directory
        }
    "Folder Structure built" 
}
#***************************
# EndFunction Verify-Folders
#***************************

#**********************
# Function Get-FileName
#**********************
Function Get-FileName {
    [CmdletBinding()]
    Param($initialDirectory)
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "TXT (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    Return $OpenFileDialog.filename
}
#*************************
# EndFunction Get-FileName
#*************************

#**************************
# Function Convert-To-Excel
#**************************
Function Convert-To-Excel {
    [CmdletBinding()]
    Param()
   "Converting HostList from $Global:VCname to Excel"
    $workingdir = $Global:Folder+ "\*.csv"
    $csv = dir -path $workingdir

    foreach($inputCSV in $csv){
        $outputXLSX = $inputCSV.DirectoryName + "\" + $inputCSV.Basename + ".xlsx"
        ### Create a new Excel Workbook with one empty sheet
        $excel = New-Object -ComObject excel.application 
        $excel.DisplayAlerts = $False
        $workbook = $excel.Workbooks.Add(1)
        $worksheet = $workbook.worksheets.Item(1)

        ### Build the QueryTables.Add command
        ### QueryTables does the same as when clicking "Data » From Text" in Excel
        $TxtConnector = ("TEXT;" + $inputCSV)
        $Connector = $worksheet.QueryTables.add($TxtConnector,$worksheet.Range("A1"))
        $query = $worksheet.QueryTables.item($Connector.name)


        ### Set the delimiter (, or ;) according to your regional settings
        ### $Excel.Application.International(3) = ,
        ### $Excel.Application.International(5) = ;
        $query.TextFileOtherDelimiter = $Excel.Application.International(5)

        ### Set the format to delimited and text for every column
        ### A trick to create an array of 2s is used with the preceding comma
        $query.TextFileParseType  = 1
        $query.TextFileColumnDataTypes = ,2 * $worksheet.Cells.Columns.Count
        $query.AdjustColumnWidth = 1

        ### Execute & delete the import query
        $query.Refresh()
        $query.Delete()

        ### Get Size of Worksheet
        $objRange = $worksheet.UsedRange.Cells 
        $xRow = $objRange.SpecialCells(11).ow
        $xCol = $objRange.SpecialCells(11).column

        ### Format First Row
        $RangeToFormat = $worksheet.Range("1:1")
        $RangeToFormat.Style = 'Accent1'

        ### Save & close the Workbook as XLSX. Change the output extension for Excel 2003
        $Workbook.SaveAs($outputXLSX,51)
        $excel.Quit()
    }
    ## To exclude an item, use the '-exclude' parameter (wildcards if needed)
    remove-item -path $workingdir 

}
#*****************************
# EndFunction Convert-To-Excel
#*****************************



#***************
# Execute Script
#***************
CLS
$ErrorActionPreference="SilentlyContinue"


"=========================================================="
Verify-Folders
"----------------------------------------------------------"
"Get Target List"
$inputFile = Get-FileName $Global:Folder
"----------------------------------------------------------"
"Reading Target List"
$CompName = Get-Content $inputFile
"----------------------------------------------------------"
"Processing Target List"

Add-Content -Path $Global:Folder\ResponseTimes.csv -Value "HostName,PingResponseTime"
$Count = 1
foreach ($comp in $CompName) { 
    Write-Progress -Id 0 -Activity 'Gathering Ping Responses' -Status "Processing $($count) of $($CompName.count)" -CurrentOperation $_.Name -PercentComplete (($count/$CompName.count) * 100) 
    $test = (Test-Connection -ComputerName $comp -Count 4  | measure-Object -Property ResponseTime -Average).average 
    $response = ($test -as [int] ) 
         
    write-Host "The Average response time for" -ForegroundColor Green -NoNewline;write-Host " `"$comp`" is " -ForegroundColor Red -NoNewline;;Write-Host "$response ms" -ForegroundColor Black -BackgroundColor white 
    Add-Content -Path $Global:Folder\ResponseTimes.csv -Value "$comp,$response ms"
    $Count++
}
"----------------------------------------------------------" 
Convert-To-Excel
"----------------------------------------------------------" 