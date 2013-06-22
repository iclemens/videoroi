%
% This script demonstrates the GUITabPanel component.
%

clear all; close all;
w = GUIWindow();

tabs = GUITabPanel();
tab1 = tabs.addTab('Video');
tab2 = tabs.addTab('ROIs');
tab3 = tabs.addTab('Data');
w.addComponent(tabs);

vb = GUIBoxArray();
vb.setHorizontalDistribution([NaN 150]);
vb.addComponent(GUIButton('Button on tab 1'));
vb.addComponent(GUIButton('Button on tab 1'));

tab1.addComponent(vb);
tab2.addComponent(GUIButton('Button on tab 2'));
tab3.addComponent(GUIToggleButton());

tabs.switchTo(1);
