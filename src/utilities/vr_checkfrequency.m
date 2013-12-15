function valid = vr_checkfrequency(freq)
% Returns true if the frequency specified is invalid, false otherwise

  valid = false;

  if isreal(freq) && ~isnan(freq) && ~isinf(freq)
    valid = true;
  end
end