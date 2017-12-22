function log-it {
    Param(
            [Parameter(Mandatory=$true)][String]$logfile,
            [Parameter(Mandatory=$true)][String]$logstring
        )
    ##write-host  $logstring
    $date = Get-Date -Format HH:mm:ss.fff
    $newlogstring = $date + " " + $logstring
    $mypath = $logfile.Substring(0, $logfile.lastIndexOf('\'))
    if(!(test-path $mypath)){  
        new-item -path $mypath -type Directory | out-null
    }
    $newlogstring | out-file $logfile -append
}

function load-collectionfile {
param (
	$collectionfile
)
    log-it -logfile $logfile -logstring  "FUNCTION: load-collectionfile"
    log-it -logfile $logfile -logstring  "Parameter: $collectionfile"
	#read-host "Testing breakpoint FUNCTION:  load-collectionfile"
    log-it -logfile $logfile -logstring  "config file name $collectionfile"
    if(test-path $collectionfile){
        $csv = Import-CSV -path $collectionfile -Delimiter ","
        return $csv
    }else{
            throw "Config file does not exist"
    }
}

function git-clonerepo {
    param (
        $repo,
        $path
    )
    log-it -logfile $logfile -logstring  "FUNCTION: git-clonerepo"
    log-it -logfile $logfile -logstring  "Parameter: $repo"
    log-it -logfile $logfile -logstring  "Parameter: $path"	
    log-it -logfile $logfile -logstring  "Parameter: $(get-location)"
	#read-host "Testing breakpoint FUNCTION:  git-clonerepo"
    $oldpath = get-location
	if(!$(test-path -path $path)){
        New-item -path $path -type Directory | out-null
	}
	
    set-location -path $path	
    log-it -logfile $logfile -logstring  "Set-location now: $(get-location)"
    git clone $repo
    set-location -path $oldpath	
    log-it -logfile $logfile -logstring  "Set-location now: $(get-location)"
}

function prep-directory {
    param (
        $path
    )
    log-it -logfile $logfile -logstring  "FUNCTION: prep-directory"
    log-it -logfile $logfile -logstring  "Parameter: $path"
	#read-host "Testing breakpoint FUNCTION: prep-directory"	
	$folders = get-childitem -path "$path"
	foreach ($folder in $folders){
    log-it -logfile $logfile -logstring  "Removing $path\$folder"
		remove-item -path "$path\$folder" -force -recurse -confirm:$false
		}
}

function collect-configfiles {
    param(
        $csv,
        $path
    )
    log-it -logfile $logfile -logstring  "FUNCTION: collect-configfiles"
    log-it -logfile $logfile -logstring  "Parameter: $csv"
    log-it -logfile $logfile -logstring  "Parameter: $path"
	#read-host "Testing breakpoint FUNCTION: collect-configfiles"
	$oldpath = get-location
	set-location -path $path	
    log-it -logfile $logfile -logstring  "Set-location now: $(get-location)"
    foreach ($item in $csv){
        log-it -logfile $logfile -logstring  "Collecting file: $item.file"
		$file = $item.file
           log-it -logfile $logfile -logstring  "Pulling file"
           win-pullfile -file $file -path $path
   
       ##read-host "continue?"
    }
	set-location -path $oldpath	
    log-it -logfile $logfile -logstring  "Set-location now: $(get-location)"
}

function win-pullfile {
    param(
        $file,
        $path
    )
    log-it -logfile $logfile -logstring  "FUNCTION: win-pullfile"
    log-it -logfile $logfile -logstring  "Parameter: $file"
    log-it -logfile $logfile -logstring  "Parameter: $path"
    $convertedfile = $file -replace ':',''
    $destination = $path + "\" + $($convertedfile.Substring(0, $convertedfile.lastIndexOf('\')))
    log-it -logfile $logfile -logstring  "$file $path$convertedfile"
    if(!(test-path $destination)){  
        New-item -path $destination -type Directory | out-null
    }
    Copy-Item -path $file -Destination $destination
}

function commit-configfiles {
    param (
        $date,
        $repo,
        $path
    )
    log-it -logfile $logfile -logstring  "FUNCTION: commit-configfiles"
    log-it -logfile $logfile -logstring  "Parameter: $date"
    log-it -logfile $logfile -logstring  "Parameter: $repo"
    log-it -logfile $logfile -logstring  "Parameter: $path"	
    log-it -logfile $logfile -logstring  "Parameter: $(get-location)"
	#read-host "Testing breakpoint FUNCTION: commit-configfiles"
    $oldpath = get-location
    set-location -path $path
    git add *
    git commit -m "commit on $date"
    git push
    set-location -path $oldpath
}

function backup-files {
    Begin
    {

        #prepare function variables
        $date = Get-Date -Format "MM_dd_yyyy_HH_mm_ss_fff"
        $servername = $("$env:computername.$env:userdnsdomain").tolower()
        $configpath = "C:\ProgramData\config-pullfiles\"
		$configfile = "$configpath$servername-pullfiles.conf"
		$collectionfile = "$configpath$servername-pullfiles.csv"
        $collectionpath = "$env:temp\temp-pullfiles\"
		$collectionfullpath = "$collectionpath$servername"
        $logname = "backup-files-$date.log"
		$logpath = $configpath
        $logfile = $logpath + $logname

        $serverorganization = "replace with subproject name"
        
        $gitlabbaseurl="https://github/replacewithreponame/"
        $gitlabfullurl="$gitlabbaseurl$serverorganization/$servername.git"


        log-it -logfile $logfile -logstring  "$logfile"
        log-it -logfile $logfile -logstring  "$servername"
        log-it -logfile $logfile -logstring  "$serverorganization"
        log-it -logfile $logfile -logstring  "$gitlabfullurl"
        log-it -logfile $logfile -logstring  "Starting script $logname"
    }
    Process
    {
		$csv = load-collectionfile -collectionfile $collectionfile
		
        git-clonerepo -repo $gitlabfullurl -path $collectionpath
		
        prep-directory -path $collectionfullpath
		
        collect-configfiles -csv $csv -path $collectionfullpath

		commit-configfiles -date $date -repo $gitlabfullurl -path $collectionfullpath
    }
    End
    {
        log-it -logfile $logfile -logstring  "Finshed script $functionname"
    }
}
