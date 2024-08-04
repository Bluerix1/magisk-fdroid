#!/usr/bin/env bash

file_name="magisk-fdroid.zip"

7z a -mx9 \
  "$file_name" \
  LICENSE \
  META-INF \
  README.md \
  compress.sh \
  module.prop \
  system

7z l "$file_name"
