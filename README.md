# RuffleSegmentation
To segment ruffles and cell bodies from 2D time lapse fluorescence images of actin-labeled cells.


## Overview of the method

> Raw video of an actin-labeled cell expressing ruffles

https://github.com/JungsikNoh/RuffleSegmentation/blob/main/doc/rawImages.mp4

> Moving-median normalized images

- Compute the moving median intensity over 51 time frames at each pixel.
- Normalized intensity = raw intensity / mov-median intensity * 100
- Ruffles are better represented by temporal high-frequency signals.

https://github.com/JungsikNoh/RuffleSegmentation/blob/main/doc/normalizedImages.mp4

> Segmented areas with high normalized intensities using Multi-Scale-Automatic (MSA) segmentation

https://github.com/JungsikNoh/RuffleSegmentation/blob/main/doc/MSASeg_maskedImages_numVotes_40.mp4

> Ruffle-segmented images

https://github.com/JungsikNoh/RuffleSegmentation/blob/main/doc/ruffle_annotated_Images.mp4





