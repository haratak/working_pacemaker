#!/usr/bin/env bash
set -e

flutter drive --target=test_driver/timer_driver/timer_driver_target.dart \
   --driver=test_driver/timer_driver/timer_driver.dart

flutter drive --target=test_driver/settings_driver/duration_changes_driver_target.dart \
    --driver=test_driver/settings_driver/duration_changes_driver.dart
