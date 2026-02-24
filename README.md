# RuffleSegmentation
To segment ruffles and cell bodies from 2D time lapse fluorescence images of actin-labeled cells.


## Overview of the method

> Raw video of an actin-labeled cell expressing ruffles

https://github.com/user-attachments/assets/559e72ba-7a9a-45ca-a217-880dacc506be

> Moving-median normalized images

- Compute the moving median intensity over 51 time frames at each pixel.
- Normalized intensity = raw intensity / mov-median intensity * 100
- Ruffles are better represented by temporal high-frequency signals.

https://github.com/user-attachments/assets/0ec7b8ae-5a5b-4aaf-8d8a-48f81f445d9c

> Segmented areas with high normalized intensities using Multi-Scale-Automatic (MSA) segmentation

https://github.com/user-attachments/assets/9dcbb277-55f2-406d-9ee8-d0ea874e2f1f

> Ruffle-segmented images

https://github.com/user-attachments/assets/65f1c7bd-b1ff-4ccd-8aed-e9a82b2b60f4






