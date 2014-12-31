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

    # Test that the bucket exists
    Try{
        Test-S3Bucket -BucketName $bucket
    }
    Catch {
        Fail-Json $result "Error. Bucket: $bucket not found. Or authorization to access bucket failed."
    }
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

    # test that local directory exists
    If (-Not (Test-Path $localdir -PathType Container)){
        Fail-Json $result "Local directory: $localdir does not exist"
    }
}

# METHOD
If ($params.method) {
    $method = $params.method.toString()

    # Check for valid method
    If (-Not ($method -match "download" -Or "upload")){
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
    If ($params.access_key){
        Fail-Json $result "Missing credential: secret_key"
    }
    Else {
        Fail-Json $result "Missing credential: access_key"
    }
}

# Upload file
If ($method -match "upload" -And $local){
    Try{
        # If a key-prefix is entered instead of a full key (including file name), append local file name to key for upload
        If ($key[$key.length-1] -eq "/" -Or "\") {
            $basename = Split-Path $local -Leaf
            Write-S3Object -BucketName $bucket -Key $key$basename -File $local
            $result.changed = $true
        }
        Else {
            Write-S3Object -BucketName $bucket -Key $key -File $local
            $result.changed = $true
        }
    Catch {
        Fail-Json $result "Error uploading $local and saving as $buckey$key"
    }
}
# Upload all files within a directory
# * When uploading an entire directory, the key specified must just be the key-prefix so that the file names will be appended
ElseIf ($method -match "upload" -And $localdir){
    Try {
        If (-Not ($key[$key.length-1] -eq "/" -Or "\")){
            Fail-Json $result "Invalid key-prefix entered for uploading an entire directory. Example key: 'Path/To/Save/To/'"
        }

        Write-S3Object -BucketName $bucket -Folder $localdir -KeyPrefix $key
        $result.changed = $true
    }
    Catch {
        Fail-Json $result "Error occured when uploading files from $localdir to $bucket$key"
    }
}

# Download file
If ($method -match "download" -And $local){
    Try{
        Read-S3Object -BucketName $bucket -Key $key -file $local
        $result.changed = $true
    }
    Catch {
        Fail-Json $result "Error downloading $bucket$key and saving as $local"
    }
}
# Download all files within an s3 key-prefix virtual directory
ElseIf ($method -match "download" -And $localdir){
    Try{
        If (-Not ($key[$key.length-1] -eq "/" -Or "\")){
            Fail-Json $result "Invalid key-prefix entered for downloading an entire virt directory. Example key: 'Path/To/Save/To/'"
        }

        Read-S3Object -BucketName $bucket -KeyPrefix $key -Folder $localdir
        $result.changed = $true
    }
}



