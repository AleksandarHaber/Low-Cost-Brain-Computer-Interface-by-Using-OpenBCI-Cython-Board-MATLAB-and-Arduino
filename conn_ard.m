clear all
clc
delete(instrfindall); % it is a good practice that we call this

% here we define the main communication parameters
arduino=serial('/dev/cu.usbmodem101','BaudRate',9600,'DataBits',8);    

% We create a serial communication object on port /dev/cu.usbmodem101
% in your case, the Ardunio microcontroller might not be on /dev/cu.usbmodem101, to
% double check, go to the Arduino editor, and on click on "Tools". Under the "Tools" menu, there
% is a "Port" menu, and there the number of the communication port should
% be displayed

% Define some other parameter, check the MATLAB help for more details 
InputBufferSize = 8;
Timeout = 0.1;
set(arduino , 'InputBufferSize', InputBufferSize);
set(arduino , 'Timeout', Timeout);
set(arduino , 'Terminator', 'CR');
% Now, we are ready to go:

fopen(arduino); % initiate arduino communication
pause(0.5)
fprintf(arduino,'1960>') %send the control sequence, '1'- direction, '960'- number of steps, '>'- end marker
fprintf(arduino,'0123>')

% Let us see did Arduino microcontroller receive the sequence (only the number of steps)
y=fscanf(arduino,'%f')
%sss=fgets(arduino)
% Close the communication port
fclose(arduino);