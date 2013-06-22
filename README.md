videoroi
========

Matlab script for defining regions of interest in videos.

To start the tool, add the _src_ directory to the Matlab path and run _VideoROITool_.
 
The software stores all stimulus material, ROI definitions and datasets in a special directory called a _project directory_. At the start of the program, it will ask you to open a project. To start a new project, just create an empty directory and open that. To continue orking on a past project, just open your project directory. You can then use the GUI to add stimuli or datasets to your project.


Concepts
--------

All projects consist of two types of items:
 * Stimuli

   Either images or videos which are shown to the participant during the experiment. For each stimulus regions of interest (ROIs) can be defined. These are currently limited to rectangular areas and are specified in native stimulus coordinates.

 * Datasets

   There is one dataset containing eye movement information for every participant. Each dataset consists of a number of trials, and in turn every trial contains one or more stimulus presentations. In other words, there is a per-trial list containing onset time, duration and on-screen location for every stimulus. If the stimulus is a video, every frame is considered separately.

In addition a _task_ can be set. A task is a specific set of functions which read stimulus locations from the dataset and have some insight into how the data should be analyzed (i.e. which intervals should be considered and which should not).


Copyright and license
---------------------

This software uses the mmread library.
Copyright (c) 2005, Micah Richert

Everything else:
Copyright (c) 2013 Ivar Clemens

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
