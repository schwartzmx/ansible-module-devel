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

# Will use: Add-Computer
# NOTE: Cannot have both Workgroup and Domain set.
# Also specify action: unjoin to use -UnjoinDomainCredential, also this can only be used with Domain set and not Workgroup, "Use this parameter when you are moving computers to a different domain"
# Also options (-Options <JoinOptions>) can only be set with Domain and not Workgroup
# host (optional), can get current hostname and use that
# domain (optional), people could want to just rename host
# server (optional), specify name of a domain controller, default none
# user (optional), could pull from local credentials
# pass (optional), could pull from local credentials
# timezone (optional), could keep as is.  Determine how we should accept input,  Central Standard Time or CST (also case sensitive?)
# options (optional), Join options Ex. -Options "One, Or, More, Values"
# oupath (optional), Specifies an organizational unit for the domain account
# restart (optional), default not
# unsecure (optional), unsecure join
# workgroup (optional), default WORKGROUP
# -FORCE may be required to supresss user confirmation prompt
# MAYBE USE -WhatIf to test if command would pass or fail, then run.

$restart = $false
$params = Parse-Args $args;

$result = New-Object psobject @{
    win_join = New-Object psobject
    changed = $false
}

If ($params.timezone) {
    C:\Windows\System32\tzutil /s $params.timezone.toString()
}

If ($params.host) {
    Set-Attr $result.win_join "host" $host.toString()
    $hostname = $params.host.toString()
}








If (($params.restart -eq "true") -or ($params.restart -eq "yes")) {
    Restart-Computer -Force
}

Set-Attr $result.win_join "host" $host.toString()
Set-Attr $result.win_join "restart" $restart.toString()

Exit-Json $result;