# CFA
---

This is a prototypical python3 based implementation of the CFA algorithm presented by Mistelbauer et al. ([paper](https://www.cg.tuwien.ac.at/research/publications/2013/mistelbauer-2013-cfa/)).

## Installation

To run the Server on your computer you can execute it simply by
```bash
cd Server
python3 app.py
```
Errors will then be logged into Server/error.log

To build the docker-image yourself and then run it, you can use the following commands (this may take some time):
```bash
cd Server
docker build ./ -t cfa_server
```

Alternatively, if you have an already existing image you can load it via:

```bash
docker load -i <PATH_TO_FILE>
```

Or save it again using

```bash
docker save cfa_server -o <PATH_TO_FILE>
```

To run the Server just use (-p makes it use the port on your PC, so that you can actually see the server in your browser):
```bash
docker run -p 8585:8585 cfa_server
```

## Usage

To use this tool, simply put in all the data (according to the algorithm described in the paper). 


| Field        | Input          |
| ------------- |-------------  | 
|DICOM| The .dcm file of the data to be used. |
|TIFF| The .tif file of the data to be used. |
|Isolation Mask (TIFF) |The isolation mask which needs the same shape as the original data. It will be applied as cell-wise multiplication.|
|Center Line (XML)| The Center Line, which needs to be in MeVis Format.|
|Sample Strategy| The sample strategy in which the circular rays should be samples. Additionally to "Constant Angle" and "Constant Arc", "Constant Number" is implementes.|
|Sample Frequency|The sample frequency is an integer for "Constant Number", or a float for "Constant Arc" (in mm) and "Constant Angle" (in radian).|
|Circle Step Delta|The distance in mm about which the circles should increase.|
|Centerline Step Delta|The distance in mm about which the centerline should be sampled.|
|Max Radius|The maximum radius in mm, for which shall be sampled.|
|Left/Right Aggregation Function| Several Aggregation Functions are offered for both sites: Maximum, Minimum, Average, Median. The original paper uses Maximum for the left and Minimum for the right side.|
|CONTEXT - Side| The medical side of which  the context information should be taken from (Head,Feet,Left,Right,Anterior,Posterior).|
|CONTEXT - Number of Samples|The number of samples which should be taken along the desired projection.|
|STABILITY - Kernel Radius w|The kernel radius in which the CFA image will be sampled to get the stability, the resulting Kernel has size (2w+1)x(2w+1).|
|STABILITY - Percentile|The Percentil above which the variance of the image pixel will be displayed|
|dpi| The DPI of the resulting image.|

## Stability

Since the paper gives no real information, about how excalty the stability should be calculated atop the image, we decided to make a cut at a certain percentile. E.g. if ther percentile is at 95% the highest 5% will be marked from blue (95%) to red (100%/highest value). This is not affected by DPI but only by the resolution resulting from Circle Step Delta and Centerline Step Delta. Since higher kernel radii need much more computational power, be careful when those numbers are cranked up.

## Testing

In the subfolder testing, a script can be found to test bulkwise data. One should be really careful when experimenting since the runtime may exceed expectations.