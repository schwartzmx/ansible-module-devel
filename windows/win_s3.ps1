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

$url = "http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi"
$sdkdest = "C:\AWSPowerShell.msi"

$params = Parse-Args $args;

$result = New-Object psobject @{
    win_s3 = New-Object psobject
    changed = $false
}

# Check if AWS SDK is installed
$list = Get-Module -ListAvailable
# If not download it and install
If (-Not ($list -match "AWSPowerShell")){
    Try{
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $sdkdest)
    }
    Catch {
        Fail-Json $result "Error downloading AWS-SDK from $url and saving as $sdkdest"
    }

    Try{
        msiexec.exe /i $sdkdest /qb
    }
    Catch {
        Fail-Json $result "Error installing $sdkdest"
    }

}


# Import Module
Import-Module AWSPowerShell

# Get Parameters
# BUCKET
If ($params.bucket) {
    $bucket = $params.bucket.toString()
}
Else {
    Fail-Json $result "missing required argument: bucket"
}

# KEY
If ($params.key) {
    $key = $params.key.toString()
}
Else {
    Fail-Json $result "missing required argument: key"
}

# LOCAL (file)
If ($params.local) {
    $local = $params.local.toString()

    # test that local file exists
    If (-Not (Test-Path $local)){
        Fail-Json $result "Local file: $local does not exist"
    }
}

# LOCALDIR (directory)
If ($params.localdir) {
    $localdir = $params.localdir.toString()

    # test that local file exists
    If (-Not (Test-Path $localdir -PathType Container)){
        Fail-Json $result "Local directory: $localdir does not exist"
    }
}

# METHOD
If ($params.method) {
    $method = $params.method.toString()

    If (-Not ($method -match "download" | "upload" | "sync")){
        Fail-Json $result "Invalid method parameter entered: $method"
    }
}
Else {
    Fail-Json $result "missing required argument: method"
}

# Credentials
If ($params.access_key -And $params.secret_key) {
    $access_key = $params.access_key.toString()
    $secret_key = $params.secret_key.toString()

    # Set credentials to default profile (maybe specify a profile as a param?)
    Set-AWSCredentials -AccessKey $access_key -SecretKey $secret_key -StoreAs default
}
ElseIf ($params.access_key -Or $params.secret_key) {
    Fail-Json $result "Error only one key for AWS credentials was found. AK: $access_key SK: $secret_key"
}

# Upload

# Download

# Sync