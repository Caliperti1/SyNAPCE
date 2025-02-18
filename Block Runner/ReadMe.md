# Block Runner 

## Overview 
Block Runner is MATLAB based video game where a user must navigate themselves thorugh a series of blocks by shifting their center of mass on a force plate. This code is onw used as part of a protocol to evaluate a component of postural conrtol coined postural agility. See the team's recent publication (mdpi.com/1424-8220/24/23/7420) for an overview of the procedure. Block runner is a bespoke program built on top of an AMTI software package for interfacing with their forceplate hardware. 

## Acknowledgemnts 
Dr. Josiah Steckenrider
Chris Aliperti
Caspian Bell

The AMTI software was acquired through direct communication with AMTI. Accompanying drivers and support can be found at (https://www.amti.biz/support/downloads/)

## Getting Started 

### Requirements 
  - An AMTI force plate (the ACG-O model works, as may others, but they have not been tested) 
  - A recent version of Matlab (We are running 2024b)
  - The programs contained in this folder
  - Drivers and .dll (file explained below)

### Setup 
go to https://www.amti.biz/support/downloads/, navigate to “Software & Drivers”, and download the .zip file entitled “AMTI USB Device Drivers (32-bit & 64-bit)”. Extract the folder on your computer and follow the instructions in the included “Drivers Installation Instructions” guide. 

move the file named “AMTIUSBDevice.dll” into the following location on your computer: C:\WINDOWS\System32. 

### Use 
The folder contains many files which there is no reason to open as they only serve to support the DLL allowing Matlab to interface with the Matlab code. The only four codes that should require any altering:
 (1) PosturalControlProcedure
 (2) Block_Runner_Forceplate
 (3) Block_Runner_PostProcessing
 (4) DLLAcquisition_Block_Runner


## Contents 

**PosturalControlProcedure.m** - This is the main script to excute one possible procedure that can be tested with the code. The currently loaded procedure is the one outlined in the above mentioned paper.  It prompts the user to provide basic subject info and randomly decides if the first trials will be hard or soft surface. It then calls Block_Runner_Forceplate to run six trials, prompting the investigatort to switch the surface condition after the first three. After each trial, Block_Runner_PostProcessing is run with the global variables created by Block_Runner_Forceplate. Near the top of the code the three locations for data storage are defined. Our group crrently stores the data on a shared folder on a Teams page. If storing to the same teams page, as long as you have the teams files synced to your computer, the file path should be the same with just the user name changed. If subject data has not yet been entered for a subject, you can enter ‘y’ when prompted and input all subject data which will be stored in the subject data excel, whose file path is defined by trialsheetlocation. The COP data for each trial along with the time and penalty variables are stored as a .mat file in the folder described by the variable Path. The final file path, datalocation, is the excel which the parameters from each run of Block_Runner_PostProcessing.  

**Block_Runner_Forceplate.m** - This is the framework for creating and setting up the block runner game, creating a 2D projection of a 3D arena using pinhole camera dynamics. It contains the variables that control how the game runs, such as focal length, camera position, and velocity, as well as file location for data storage. The code generates blocks as a matrix of corners determined around the location of the block stored in r_wbs. The locations of the corners are described in three reference frames, the block to the corners denoted by b, the world to the block, denoted by wbs, and the camera to the blocks, denoted by cw. After each corner is defined relative to the camera, the focal length is used to transform the x and z positions of the corners onto the 2D x and y position they will be graphed at depending on how far from the camera in the y direction they are. The code currently has a set configuration of blocks, but they can be randomly generated if config is set to zero. Additional configurations of blocks can also be added. The code then prompts the user for how many screens are connected so that if a secondary screen is available it will graph the game on that screen (We execute our protocol by projecting the game to a large TV mounted in from of the subject.) Once this number is entered, it creates the initial graph and attempts to connect to the force plate, giving an error if it does not connect. Once connected, it waits for a button press to begin running the game through DLLAcquisition_Block_Runner.  

**DLLAcquisition_Block_Runner.m** - This is built primarily on the code provided by AMTI, DLLAcquision, which is also included in the folder. The code runs continuously as the game is played and moves the blocks and arena towards the camera along the y axis every loop, retransforming and graphing it. The code also moves the camera along the x axis by the y value of the COP times the set sensitivity. It stores the COP position, time, and whether the camera is within a block for each iteration to global variables which can be used in other scripts after the game is finished. If the camera x and y position are within a block, or outside of the arena, all of the blocks turn red until they exit it to inform them that they are accumulating the penalty. This code will run 2002 times until the camera passes over the far y end of the arena and the game stops. 

**Block_Runner_PastProcessing.m** - Once a trial of the game is complete, this calculates given parameters from the raw COP data and stores it in an excel file. It calculates the total excursions of the COP in both the AP and ML directions, the average velocity in both direction, the average ML acceleration, the total penalty, the modulus, and the time to new stability. All of this data is stored on one excel with each time the code is run it creating a new line in the excel.  

## Troubleshooting 

## Updates in progress 

(1) Moving all user defined variables to a config function to avoid users from having to manipulate code in multiple scripts
(2) Updating data management to comply with new protocol
