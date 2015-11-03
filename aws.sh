#!/bin/bash
. "$COMPONENT_INC_SH" || exit 1

[[ -x /usr/bin/aws ]] && exit 0

component require unzip

TEMP=
eval "$(component tempdir TEMP)"
[[ -n "$TEMP" ]] || exit 1
cd "$TEMP" || exit 1

curl -s \
	-o "$TEMP/awscli-bundle.zip" \
	"https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"

cd "$TEMP" || exit 1
unzip awscli-bundle.zip || exit 1
sudo ./awscli-bundle/install \
	-i /usr/aws \
	-b /usr/bin/aws
