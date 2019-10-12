#!/bin/bash
#
# This script is meant to run in the User Data of an EC2 instance to mount two persistent EBS volumes, one by ID and
# one by tag.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# The variables below are set via Terraform interpolation

# Mount one EBS Volume by ID
mount-ebs-volume \
  --aws-region "${aws_region}" \
  --volume-id "${volume_1_id}" \
  --device-name "${device_1_name}" \
  --mount-point "${mount_1_point}" \
  --owner "${owner}"

# Mount the other EBS Volume by tag
mount-ebs-volume \
  --aws-region "${aws_region}" \
  --volume-with-same-tag "${volume_2_tag}" \
  --device-name "${device_2_name}" \
  --mount-point "${mount_2_point}" \
  --owner "${owner}"
