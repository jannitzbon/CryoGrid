function is_valid_date_ddmmyyyy( date_string )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if ~isa(date_string, 'char')
    error('A date string is expected')
elseif strcmp(date_string,cell2mat(regexp(date_string,'\d{2}\.\d{2}\.\d{4}','match'))) == 0 | ~ismember(str2num(date_string(1:2)),[1:1:31]) | ~ismember(str2num(date_string(4:5)),[1:1:12]) 
    error('A date is expected, under the format dd.mm.yyyy, with dd ranging from 1 to 31 and mm from 1 to 12')
end

end

