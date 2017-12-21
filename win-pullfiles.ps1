function log-it {
    #logging function
    Param(
            [Parameter(Mandatory=$true)][String]$logfile,
            [Parameter(Mandatory=$true)][String]$logstring
        )
    write-host  "FUNCTION: log-it"
    write-host  $logstring
    $date = Get-Date -Format HH:mm:ss.fff
    $newlogstring = $date + " " + $logstring
    $mypath = $logfile.Substring(0, $logfile.lastIndexOf('\'))
    if(!(test-path $mypath)){  
        new-item -path $mypath -type Directory | out-null
    }
    $newlogstring | out-file $logfile -append
}

function load-configfile {
    log-it -logfile $logfile -logstring  "FUNCTION: load-configfile"
    $configfile = "C:\ProgramData\config-pullfiles\$env:computername-pullfiles.csv"
    log-it -logfile $logfile -logstring  "config file name $configfile"
    if(test-path $configfile){
        $mycsv = Import-CSV -path $configfile -Delimiter ","
        collect-configfiles -configlist $mycsv
    }else{
            throw "Config file does not exist"
    }
}

function collect-configfiles {
    param(
        $configlist
    )
    log-it -logfile $logfile -logstring  "FUNCTION: collect-configfiles"
    $path = "$env:temp\win-pullfiles\$env:computername\"
    log-it -logfile $logfile -logstring  "path is $path"
    if(test-path $path){
        log-it -logfile $logfile -logstring  "path exists, deleting folder"
        remove-item -Path $path -Recurse -Confirm:$false
        new-item -path $path -ItemType Directory
    }else{
        log-it -logfile $logfile -logstring  "path does not exist"
        new-item -path $path -ItemType Directory
    }
    foreach ($item in $configlist){
        log-it -logfile $logfile -logstring  $item.file
        if(test-path -path $item.file){
           log-it -logfile $logfile -logstring  "pulling file"
           win-pullfile -file $item.file -configfolderroot $path
       }else{
           log-it -logfile $logfile -logstring  "File does not exist."
       }
       #read-host "continue?"
    }
}

function win-pullfile {
    param(
        $file,
        $configfolderroot
    )
    log-it -logfile $logfile -logstring  "FUNCTION: win-pullfile"
    $convertedfile = $file -replace ':',''
    $destination = $configfolderroot + "\" + $($convertedfile.Substring(0, $convertedfile.lastIndexOf('\')))
    log-it -logfile $logfile -logstring  "$file $configfolderroot$convertedfile"
    if(!(test-path $destination)){  
        New-item -path $destination -type Directory | out-null
    }
    Copy-Item -path $file -Destination $destination
}

function backup-files {
    Begin
    {
        $functionname = "backup-files"
        $logfile = "C:\ProgramData\config-pullfiles\" + $functionname + "-$(Get-Date -Format "MM_dd_yyyy_HH_mm_ss_fff").log"
        log-it -logfile $logfile -logstring  "Starting script $functionname"
    }
    Process
    {
        load-configfile
    }
    End
    {
        log-it -logfile $logfile -logstring  "Finshed script $functionname"
    }
}
