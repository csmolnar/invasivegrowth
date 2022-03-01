
# Relative invasiveness value

This repository contains code for imaging based analysis and calculation of **relative invasiveness value** of invasive growth phenotype in manuscript *Compensatory evolution promotes the emergence of morphological novelties* by Farkas et al. 2022.

## Setting environment

The path to images can be set in ```setOptions.m```.

The code is working with the following folder structure (NOTE: ```results``` folder is automatically created by the code):

```
/<Project directory>/ # options.projectDir
    ├── data
    |       ├── <Plate 1> # options.plateName
    |       |       └── bottom # options.imagingType
    |       |              ├── <pre-wash image 1> # options.beforeRegexp
    |       |              ├── <post-wash image 1> # options.afterRegexp
    |       |              ├── <pre-wash image 2>
    |       |              ├── <post-wash image 2>
    |       |              └── ...
    |       ├── <Plate 2> 
    |       |        └── ...
    |       └── ...
    └── results
            ├── <Plate 1> # options.plateName
            ├── <Plate 2> 
            └── ...
```

## Running image analysis

The analysis can be performed for a single plate by running script ```processPlateMainScript.m```.
