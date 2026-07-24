# An automated edge detection of lunar ring-moat dome structure (RMDS)

This respository provides the MATLAB implementation of the automatic edge detection algorithm for lunar ring-moat dome structure (RMDS) described in:
** Han et al., 2026. An automated edge enhancement and detection algorithm for the lunar ring-moat dome structure. **

The code is developed for identifying RMDS edge features from Lunar Reconnaissance Orbiter Narrow Angle Camera (LROC NAC) images.
The algorithm enhances weak morphological signatures of RMDS and automatically detects their locations and radii without manual interpretation.

---
# Overview

Ring-moat dome structures (RMDSs) is positive topographic features surrounded by moat-like depressions on the lunar surface.
This repostory implements a two-stage detection framework:

1. **RMDS enhancement**

   - One-dimensional signal processing along image rows with sine/cosine baisis function
   - Butterworth low-pass filtering along image columns
   - First derivative along image rows

2.  **RMDS detection**

   - Circular ring template matching
   - Circumference-based normalization
   - Response thresholding
   - DBSCAN clustering
   - Candidate selection and overlap removal

The workflow is summarized as:

LROC NAC image → Image preprocessing → RMDS feature enhancement → Circular template matching → DBSCAN clustering → Detected RMDS locations and radii

# Run test

After download and unzip this project, you can run run_test.m to see the result for the rmds4.tif. If the result is as same as the results/rmds4_edge_detection_result.png, the code will be fun.

# For other RMDS

If you want to run other example in data file (like rmds1-3.tif), you can run main.m. Before run, make sure the imageFile path at the beginning, which is suited for your own computer after download and unzip this project.

# Requirements

## Software

The code was developed and tested with:

- MATLAB R2021a or later

