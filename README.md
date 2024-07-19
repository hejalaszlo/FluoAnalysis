# FluoAnalysis
The FluoAnalysis MATLAB toolbox provides a robust and versatile platform for the integrated analysis of calcium imaging and electrophysiological data, supporting diverse neuroscience research applications.

# Install
Just download the files and add them to the Matlab path.

# Analysing sample data
You can download the sample data from https://www.dropbox.com/scl/fo/hmul4k5c5omihbmkx1b51/AB3DHfvQWlPWtZLIsDRDcYU?rlkey=ghq5k0sqop371as2iesa6d1vk&dl=0

## Traditional Ca2+ imaging, ATP application on brain slice
Acute hippocampal slices from Wistar rats, expressing GCaMP2 in both neurons and astrocytes, are subjected to application of 1 mM ATP at 200 s.
1) Extract the file "Traditional Ca2+ imaging, ATP application on brain slice.zip" anywhere on your PC
2) Start the FluoAnalysis GUI by typing FluoAnalysis in the Matlab command window.
3) Open the ATP.tif file (File>Open...). The multi-tiff file is loaded into the GUI.
4) In the "Reference image" section, select AVG, then click Use. The generated reference image appears at the top right corner. Alternatively, you can create a reference image in any other application and load it by clicking on Load in the "Reference image" section.
5) In the "Cell segmentation" section, adjust the following parameters: Ball radius (20), Threshold (0.26), Min cell size (200), Max cell size (2500), Boundary (2). 51 ROIs are identified and visualized on each images.
6) You can check the dynamics of the Ca2+ signal by using the slider below the main image.
7) Click on "Calculate ROI intensities". You can also adjust the background used for the dF/F0 calculation in the "Subtract background" section.
8) Select "Tools>Cell validation". A new GUI opens where you can classify and investigate the activity of individual cells.
9) Click on "Auto classify cells" to automatically classify cells as neurons or astrocytes. You can override the classification results by selecting each cell on the right and clicking on either "Neuron", "Glia" or "Not cell".
10) You can select "wavelet" in the "Imaging plot type" section to view the wavelet analysis of each dF/F0 trace.
