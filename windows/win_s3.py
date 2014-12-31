#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2014, Phil Schwartz <schwartzmx@gmail.com>
#
# This file is part of Ansible
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

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_s3
version_added: ""
short_description: Upload and download from AWS S3
description:
     - Uses AWS_SDK for Powershell.  If the module is not found it will be downloaded.  More Info: http://aws.amazon.com/powershell/.  Uses the SDK, with either provided credentials or IAM role credentials on EC2 instances to upload and download files from S3.  If provided, the credentials are set on the remote machine as the default profile (but only for this session).
options:
  bucket:
    description:
      - S3 Bucket (Must exist)
    required: true
    default: null
    aliases: []
  key:
    description:
      - S3 Key
    required: true
    default: null
    aliases: []
  local:
    description:
      - Local file/directory to upload or download to.
    required: yes
    default: null
    aliases: []
  method:
    description:
      - S3 method to carry out. Upload: upload file or entire directory to s3. Download: download a file from s3. Download-dir: Download entire virtual directory specified by s3 key-prefix.
    required: yes
    choices:
      - upload
      - download
      - download-dir
    default: null
    aliases: []
  rm:
    description:
      - Remove the local file after upload?
    required: no
    choices:
      - true
      - yes
      - false
      - no
    default: false
    aliases: []
  access_key:
    description:
      - AWS_ACCESS_KEY_ID: Not required if there are credentials configured on the machine, or if the machine is an ec2 instance with an IAM role.
    required: no
    default: none
    aliases: []
  secret_key:
    description:
      - AWS_SECRET_ACCESS_KEY: Not required if there are credentials configured on the machine, or if the machine is an ec2 instance with an IAM role.
    required: no
    default: none
    aliases: []

author: Phil Schwartz
'''

EXAMPLES = '''
# Upload a local file to S3
$ ansible -i hosts -m win_s3 -a "bucket=server_logs key=QA/WebServer/2015-1-1.App.log local=C:\inetpub\wwwroot\Logs\log.log method=upload rm=true access_key=EXAMPLE secret_key=EXAMPLE" all

# Playbook example
---
- name: Download Application Zip from S3
  hosts: all
  gather_facts: false
  tasks:
  - name: Download app
    win_s3:
      bucket: 'app_deploys'
      key: 'app/latest/Application.zip'
      method: 'download'
      local: 'C:\Applications\\'
      access_key: 'EXAMPLECRED'
      secret_key: 'EXAMPLESECRET'
'''
