#!/usr/bin/env bash

7z a -mx9 \
  module.zip \
  LICENSE \
  META-INF \
  README.md \
  compress.sh \
  module.prop \
  system

7z l module.zip
