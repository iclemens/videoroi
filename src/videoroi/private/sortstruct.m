function sorted = sortstruct(strct, field)
% SORTSTRUCT sorts the elements of a
% struct-array by the given field.
% Only one field is currently supported.

    [~, I] = sort({strct.(field)});
    sorted = strct(I);