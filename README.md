# FluoAnalysis
The FluoAnalysis MATLAB toolbox provides a robust and versatile platform for the integrated analysis of calcium imaging and electrophysiological data, supporting diverse neuroscience research applications. It especially focuses on the spectral analysis of imaging data acquired from hundreds of cells in a network with high sampling rate.
The toolbox provides both fully automatable script-based analysis, as well as a detailed GUI thourgh which most of the features can be used by researchers without programming background.

If you find the toolbox useful in your work, please, cite the following publication:
Péter M & Héja L. High-Frequency Imaging Reveals Synchronised Delta- and Theta-Band Ca2+ Oscillations in the Astrocytic Soma In Vivo. Int. J. Mol. Sci. 2024, 25, 8911.
https://doi.org/10.3390/ijms25168911

# Install
Just download the files and add them to the Matlab path.

# Analyzing sample data
You can download the sample data from https://www.dropbox.com/scl/fo/hmul4k5c5omihbmkx1b51/AB3DHfvQWlPWtZLIsDRDcYU?rlkey=ghq5k0sqop371as2iesa6d1vk&dl=0

## Traditional Ca2+ imaging, ATP application on brain slice
Acute hippocampal slices from Wistar rats, expressing GCaMP2 in both neurons and astrocytes, are subjected to application of 1 mM ATP at 200 s. Astrocytes are labeled with the specific marker SR-101.
1) Extract the file "Traditional Ca2+ imaging, ATP application on brain slice.zip" anywhere on your PC.
2) Start the FluoAnalysis GUI by typing FluoAnalysis in the Matlab command window.
3) Open the ATP.tif file (File>Open...). The multi-tiff file is loaded into the GUI.
4) In the "Reference image" section, select AVG, then click Use. The generated reference image appears at the top right corner. Alternatively, you can create a reference image in any other application and load it by clicking on Load in the "Reference image" section.
5) In the "Cell segmentation" section, adjust the following parameters: Ball radius (20), Threshold (0.26), Min cell size (200), Max cell size (2500), Boundary (2). 51 ROIs are identified and visualized on each images.
6) You can check the dynamics of the Ca2+ signal by using the slider below the main image.
7) Click on "Calculate ROI intensities". You can also adjust the background used for the dF/F0 calculation in the "Subtract background" section.
8) Select "Tools>Cell validation". A new GUI opens where you can classify and investigate the activity of individual cells.
9) Click on "Auto classify cells" to automatically classify cells as neurons or astrocytes. You can override the classification results by selecting each cell on the right and clicking on either "Neuron", "Glia" or "Not cell".
10) You can select "wavelet" in the "Imaging plot type" section to view the wavelet analysis of each dF/F0 trace.

## High-frequency Ca2+ imaging with simultaneous patch clamp electrophysiology
Neurons and astrocytes are loaded with the fluorescent Ca2+ indicator OGB-1 in acute cortical slices from Wistar rats. Astrocytes are labeled with the specific marker SR-101. [Mg2+] in the ACSF is reduced to 1 mM to induce increased neuronal activity. The firing of a cortical pyramidal cell is measured in whole-cell patch configuration.
1) Extract the file "High-frequency Ca2+ imaging with simultaneous patch clamp electrophysiology.zip" anywhere on your PC.
2) Start the FluoAnalysis GUI by typing FluoAnalysis in the Matlab command window.
3) Open the 20221025.mes file (File>Open...). The .mes file (spcial format for Femtonics microscopes, basically .mat files, renamed to .mes) can contain data from several imaging sessions, therefore in you need to select which session you want to analyze. The current file contains only one session. Select it and click Ok.
4) The line scan image (each line corresponds to a time point) is loaded into the main image. The background image is loaded into the Reference image frame at the top right corner. Since the line segments selected during the image acquisition already define the cells, there is no need to identify ROIs. 
5) You can check the dynamics of the Ca2+ signal by using the slider below the main image.
6) Import the electrophysiological recording by clicking on the "Add .abf file" icon in the toolbar. The electrophysiological recording is tagged by the start of the imaging session, which will be recognized during the .abf file import and only the part corresponding to the imaging session is loaded.
7) Click on "Calculate ROI intensities". You can also adjust the background used for the dF/F0 calculation in the "Subtract background" section.
8) Select "Tools>Cell validation". A new GUI opens where you can classify and investigate the activity of individual cells.
9) Select "wavelet" in the "Imaging plot type" section to view the wavelet analysis of each dF/F0 trace. Set the minimum and maximum frequencies to 5 and 30 Hz, respectively and click on "Set".
10) Select a cell that you want to analyze. Try Cell #73 as an example.
11) Zoom to a shorter timeframe on either the wavelet or the electrophysiological plot, e.g. between 50-70 sec.
12) Close the Cell classification window and return to the main GUI.
13) Create a report in Word format about the detailed analysis results of each cell (Tools>Create report).

## High-frequency Ca2+ imaging, in vivo slow-wave activity
Neurons and astrocytes are loaded with the fluorescent Ca2+ indicator OGB-1 in >300 g female Wistar rats in vivo. Astrocytes are labeled with the specific marker SR-101. Ca2+ imaging of visual cortex neurons and astrocytes is performed under ketamine/xylazine anesthesia that is known to induce permanent slow wave activity. Electrophysiological field potential is simultaneously recorded by an implanted electrode over the visual cortex.
1) Extract the file "High-frequency Ca2+ imaging, in vivo SWA.zip" anywhere on your PC.
2) Start the FluoAnalysis GUI by typing FluoAnalysis in the Matlab command window.
3) Open the invivoSWA.mes file (File>Open...). The .mes file (spcial format for Femtonics microscopes, basically .mat files, renamed to .mes) can contain data from several imaging sessions, therefore in you need to select which session you want to analyze. The current file contains only one session. Select it and click Ok. Since the image acquisition was controlled by the FluoAnalysis software, the  location of the identified ROIs are saved in the RoiSets folder. The software recognizes the presence of this folder and tries to import ROI locations from the appropriate file. Select OK.
4) The line scan image (each line corresponds to a time point) is loaded into the main image. The background image is loaded into the Reference image frame at the top right corner. 
5) You can check the dynamics of the Ca2+ signal by using the slider below the main image.
6) Import the electrophysiological recording by clicking on the "Add .abf file" icon in the toolbar. The electrophysiological recording is tagged by the start of the imaging session, which will be recognized during the .abf file import and only the part corresponding to the imaging session is loaded.
7) Click on "Calculate ROI intensities". You can also adjust the background used for the dF/F0 calculation in the "Subtract background" section.
8) Select "Tools>Cell validation". A new GUI opens where you can classify and investigate the activity of individual cells.
9) Select "wavelet" in the "Imaging plot type" section to view the wavelet analysis of each dF/F0 trace. Set the minimum and maximum frequencies to 0.5 and 4 Hz, respectively and click on "Set".
10) Select a cell that you want to analyze. Try Cell #33 as an example, but most of the cells display activity in the slow-wave activity range (0.5-2 Hz).
11) Close the Cell classification window and return to the main GUI.
12) Create a report in Word format about the detailed analysis results of each cell (Tools>Create report).
13) Save the analysis results by clicking on the floppy icon in the toolbar.
14) Create an ImagingDataSet variable by typing "ids = ImagingDataSet;" at the Matlab command window.
15) Import the analysis result saved in 12) into the dataset: "ids.loadDataFromFolder(<<path to folder where you saved your file>>);"
16) Create a summary report about all imaging sessions (currently there is only one, but you can import several sessions from a folder) by typing "ids.reportFrequencyDistribution;".
