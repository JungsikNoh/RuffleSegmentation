# RuffleSegmentation
To segment ruffles and cell bodies from 2D time lapse fluorescence images of actin-labeled cells.


## Overview of the method

> Raw video of an actin-labeled cell expressing ruffles

https://github.com/user-attachments/assets/559e72ba-7a9a-45ca-a217-880dacc506be

> Moving-median normalized images

- Compute the moving median intensity over 51 time frames (for example) at each pixel.
- Normalized intensity = raw intensity / mov-median intensity * 100
- Ruffles are better represented by temporal high-frequency signals.

https://github.com/user-attachments/assets/0ec7b8ae-5a5b-4aaf-8d8a-48f81f445d9c

> Segmented areas with high normalized intensities using Multi-Scale-Automatic (MSA) segmentation

https://github.com/user-attachments/assets/9dcbb277-55f2-406d-9ee8-d0ea874e2f1f

> Ruffle-segmented images (before truncation)

https://github.com/user-attachments/assets/65f1c7bd-b1ff-4ccd-8aed-e9a82b2b60f4

- Truncate the first and last 25 time frames (for example) because moving medians are ill-defined at the beginning and ending.

> Another example of ruffle segmentation

https://github.com/user-attachments/assets/fb35ce7d-f570-4290-90ca-22add2f1c969




## Software requirement

Matlab codes for RuffleSegmentation run on top of the Matlab package "u-segment" by Danuser lab ([u-segment](https://github.com/DanuserLab/u-segment)).

## Main function

Run [ML_ruffleSegmentation()](https://github.com/JungsikNoh/RuffleSegmentation/blob/main/code/RuffleSegmentation/ML_ruffleSegmentation.m)
to process a list of movie data objects. 

## More information
- [Output examples](example_of_output/08262023-subset)  

## Contact

Jungsik Noh (jungsik.noh@utsouthwestern.edu)













