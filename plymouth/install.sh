#!/bin/bash
# Installs the sphinx-ascii boot splash and rebuilds the initramfs. Run with sudo.
# Undo: sudo plymouth-set-default-theme bgrt -R
set -e
cp -r "$(dirname "$0")/sphinx-ascii" /usr/share/plymouth/themes/
plymouth-set-default-theme sphinx-ascii -R
echo "Done. Reboot to see it."
