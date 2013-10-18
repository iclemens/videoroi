function regionPositions = vr_regiontoscreencoords(regionPositions, stimulusInfo, stimulusPosition)  
  for r = 1:size(regionPositions, 1)
    regionPositions(r, 1, 1) = regionPositions(r, 1, 1) .* stimulusPosition(3) / stimulusInfo.width + stimulusPosition(1);
    regionPositions(r, 1, 2) = regionPositions(r, 1, 2) .* stimulusPosition(4) / stimulusInfo.height + stimulusPosition(2);
  
    regionPositions(r, 1, 3) = regionPositions(r, 1, 3) .* stimulusPosition(3) / stimulusInfo.width;
    regionPositions(r, 1, 4) = regionPositions(r, 1, 4) .* stimulusPosition(4) / stimulusInfo.height;
  end  
end