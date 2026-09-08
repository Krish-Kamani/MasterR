#!/bin/bash
cd "$HOME/GAMES/CarX Street" || exit 1
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json prime-run wine "CarX Street.exe"
