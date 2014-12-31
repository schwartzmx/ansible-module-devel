#!powershell
# This file is part of Ansible
#
# Copyright 2014, Phil Schwartz <schwartzmx@gmail.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;

$result = New-Object psobject @{
    win_zip = New-Object psobject
    changed = $false
}

# Requires PSCX, will be installed if it isn't found
# Can be useful and a must-have for running other useful scripts
# Pscx-3.2.0.msi
$url = "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=pscx&DownloadId=923562&FileTime=130585918034470000&Build=20959"
$dest = "C:\Pscx-3.2.0.msi"

# Global flags
$isLeaf = $false
$isContainer = $false

# Check if PSCX is installed
$list = Get-Module -ListAvailable
# If not download it and install
If (-Not ($list -match "PSCX")) {
    Try {
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $dest)
    }
    Catch {
        Fail-Json $result "Error downloading PSCX from $url and saving as $dest"
    }
    Try {
        msiexec.exe /i $dest /qb
    }
    Catch {
        Fail-Json $result "Error installing $dest"
    }
    Set-Attr $result.win_zip "pscx_status" "pscx was installed"
}
Else {
    Set-Attr $result.win_zip "pscx_status" "present"
}

# Import
Try {
    Import-Module PSCX
}
Catch {
    Fail-Json $result "Error importing module PSCX"
}

# Get Params (SRC, DEST, RM)
# SRC
# Detect if file or directory
If ($params.src) {
    $src = $params.src.toString()

    If(Test-Path $src -PathType Leaf) {
        $isLeaf = $true
    }
    ElseIf (Test-Path $src -PathType Container) {
        $isContainer = $true
    }
    Else {
        Fail-Json $result "Specified src: $src is not a valid file or directory"
    }

}
Else {
    Fail-Json $result "missing required argument: src"
}

# DEST
If ($params.dest) {
    $dest = $params.dest.toString()

    If (Test-Path $dest -PathType Container) {
        Fail-Json $result "Error in dest arg. Please provide the desired zip file name at the end of the path. (C:\Users\Path\Ex.zip)"
    }


    If (-Not ([System.IO.Path]::GetExtension($dest) -match ".zip")) {
        $dest = $dest + ".zip"
    }

}
Else {
    Fail-Json $result "missing required argument: dest"
}

#RM
If ($params.rm){
    $rm = $true
}
Else {
    $rm = $false
}

# Zip
Try {
    # On success Write-Zip writes to std-out. This is the reason for piping to out-null (And also b/c their -Quiet switch won't work).
    # This allows for the try-catch to still catch errors, but not fail on success output.
    Write-Zip -Path $src -OutputPath $dest -Level 9 -IncludeEmptyDirectories | out-null
    $result.changed = $true

    If ($rm){
        Try {
            Remove-Item -Path $src -Force -Recurse
            Set-Attr $result.win_zip "rm" "removed $src"
        }
        Catch {
            Fail-Json $result "Error removing $src"
        }
    }
}
Catch {
    $directory = [System.IO.Path]::GetDirectoryName($dest)
    If (-Not (Test-Path -Path $directory -PathType Container)) {
        Fail-Json $result "Directory: $directory does not exist in the dest provided."
    }
    Else {
        Fail-Json $result "Error zipping $src to $dest."
    }
}

Set-Attr $result.win_zip "src" $src.toString()
Set-Attr $result.win_zip "dest" $dest.toString()

Exit-Json $result;


