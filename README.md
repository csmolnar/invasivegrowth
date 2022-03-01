
# Relative invasiveness value

This repository contains code for imaging based analysis and calculation of **relative invasiveness value** of invasive growth phenotype in manuscript *Compensatory evolution promotes the emergence of morphological novelties* by Farkas et al. 2022.

## Setting environment

The path to images can be set in ```setOptions.m```.

The code is working with the following folder structure (NOTE: ```results``` folder is automatically created by the code):

```
/<project directory>/ # options.projectDir
    ├── data
    |       ├── <plate 1> # options.plateName
    |       |       └── <imaging type> # options.imagingType, default is bottom
    |       |              ├── <pre-wash image 1> # options.beforeRegexp
    |       |              ├── <post-wash image 1> # options.afterRegexp
    |       |              ├── <pre-wash image 2>
    |       |              ├── <post-wash image 2>
    |       |              └── ...
    |       ├── <plate 2> 
    |       |        └── ...
    |       └── ...
    └── results
            ├── <plate 1> # options.plateName
            |       ├── results_<plate 1>_<imaging type>.csv
            |       ├── <segmentation result 1>
            |       ├── <segmentation result 2>
            |       └── ...
            |       
            ├── <plate 2> 
            └── ...
```

## Running image analysis

The analysis can be performed for a single plate by running script ```processPlateMainScript.m```. The measured values will be saved under ```results``` directory.
