function [d_min, d_max] = pixel_data_type_min_max(bits_per_pel)
    if bits_per_pel==8
        d_min=0;
        d_max=255;
    elseif bits_per_pel==16
        d_min=0;
        d_max=65535;
    else
        % This should not ever happen.
        d_min=0;
        d_max=1;
    end            
end
