#!/bin/bash

cd app && fvm flutter build appbundle $1 --target-platform android-arm,android-arm64,android-x64 --obfuscate --split-debug-info=./android/app/release