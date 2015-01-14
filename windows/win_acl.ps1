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

# win_acl module (File/Resources Permission Additions/Removal)
$params = Parse-Args $args;

$result = New-Object psobject @{
    win_acl = New-Object psobject
    changed = $false
}

# params
# user = user/group
# src = file/folder
# type = allow/deny
# rights = full-control/modify etc
# inherit = ContainerInherit, ObjectInherit = examples
# propagation = None

If ($params.src) {
    $src = $params.src.toString()
}
Else {
    Fail-Json $result "missing required argument: src"
}

If ($params.user) {
    $user = $params.user.toString()
}
Else {
    Fail-Json $result "missing required argument: user.  specify the user or group to apply permissions."
}

# maybe use state instead of type
If ($params.type -eq "allow") {
    $type = $true
}
ElseIf ($params.type -eq "deny") {
    $type = $false
}
Else {
    Fail-Json $result "missing required argument: type. specify whether to allow or deny the specified rights."
}

If ($params.inherit) {
    $inherit = $params.inherit.toString()
}
Else {
    $inherit = "ContainerInherit, ObjectInherit"
}

If ($params.propagation) {
    $propagation = $params.propagation.toString()
}
Else {
    $propagation = "None"
}



Try {
    $colRights = [System.Security.AccessControl.FileSystemRights]"$rights"
    $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"$inherit"
    $PropagationFlag = [System.Security.AccessControl.PropagationFlags]"$propagation"

    If ($type) {
        $objType =[System.Security.AccessControl.AccessControlType]::Allow
    }
    Else {
        $objType =[System.Security.AccessControl.AccessControlType]::Deny
    }

    $objUser = New-Object System.Security.Principal.NTAccount("$user")
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType)
    $objACL = Get-ACL $src
    $objACL.AddAccessRule($objACE)

    Set-ACL $src $objACL

    $result.changed = $true
}
Catch {
    Fail-Json $result "an error occured when setting $rights permissions on $src for $user"
}

Exit-Json $result