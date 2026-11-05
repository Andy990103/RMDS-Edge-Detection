# An automated edge detection of lunar Ring-Moat Dome Structures (RMDSs)

The code is developed for identifying RMDS edge features from Lunar Reconnaissance Orbiter Narrow Angle Camera (LROC NAC) images.
The algorithm enhances weak morphological signatures of RMDS and automatically detects their locations without manual interpretation.

---
# Overview

Ring-moat dome structures (RMDSs) is positive topographic features surrounded by moat-like depressions on the lunar surface.

This repostory implements a two-stage detection framework:

1. **RMDS enhancement**

   - One-dimensional signal processing along image rows with sine/cosine baisis function
   - Butterworth low-pass filtering along image columns
   - First derivative along image rows

2.  **RMDS detection**

   - The RMDS detection part is mainly based on the YOLO26x, which is a open source code that can be found from https://github.com/ultralytics/ultralytics.

# Dataset

Our dataset has been made public on the Zenodo website. For more details, please refer to the link: https://zenodo.org/records/23943222

# Requirements

You can use the requirements.txt to configure the environment necessary for RMDS detection part.

## Software

The code was developed and tested with:

- MATLAB R2021a or later
- Python

