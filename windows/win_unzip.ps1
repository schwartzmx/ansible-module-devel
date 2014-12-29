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
    win_unzip = New-Object psobject
    changed = $false
}

If ($params.zip) {
    $zip = $params.zip
}
Else {
    Fail-Json $result "missing required argument: zip"
}

If ($params.dest) {
    $dest = $params.dest

    If (-Not (Test-Path $dest -PathType Container)){
        New-Item -itemtype directory -path $dest
    }
}
Else {
    Fail-Json $result "missing required argument: dest"
}

If ($params.restart) {
    $restart = $params.restart | ConvertTo-Bool
}
Else {
    $restart = $false
}

Try {
    $shell_app = new-object -com shell.application
    $zip_file = $shell_app.namespace($zip)
    $destination = $shell_app.namespace($dest)
    $destination.Copyhere($zip_file.items())
    $result.changed = $true
}
Catch {
    $result.changed = $false
    Fail-Json $result "Error unzipping $zip to $dest"
}

If ($restart -eq $true) {
    Restart-Computer -Force
}



Set-Attr $result.win_unzip "zip" $zip
Set-Attr $result.win_unzip "dest" $dest

Exit-Json $result;
