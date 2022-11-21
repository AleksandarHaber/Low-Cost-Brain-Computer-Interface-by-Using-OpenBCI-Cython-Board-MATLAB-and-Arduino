% the communication between MATLAB and Cython board is established using
% the parameters described here are taken from: https://docs.openbci.com/Cyton/CytonDataFormat/
close all
clear all
clc
delete(instrfindall); % it is a good practice that we call this


% these values are specific to the Cyton board
% b - start stream character
start_ch=char('b')
% v - reset character
reset_ch=char('v')
% s - end stream character 
end_ch=char('s')
% number of packet bytes 
packet_bytes=33
% default gain volt/per count
% default Gain is 24x - which results in the follwing scale factor 
gain= 0.02235 *10^(-6) 


% set the main parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%

InputBufferSize =packet_bytes*2000*100;
% arbitary 
Timeout = 1;


cython=serial('/dev/tty.usbserial-DM03H3Z5','BaudRate',115200,'DataBits',8)
set(cython, 'InputBufferSize', InputBufferSize);
set(cython, 'Timeout', Timeout);


% open the communication port 
fopen(cython);
fwrite(cython, reset_ch, 'uchar');
% pause the execution of the code in order to allow the board to reset
% itself
pause(0.5);

% when the cython board is ready it will send '$$$', the ASCII value of the  character '$'  is 36.
% read until '$$$' is sent
temp= fread(cython, 3);

while (sum(temp(end-2:end))~=108)
   temp=[temp ; fread(cython,3)];
end
% at the end of this, you should get a warning message, and that means that
% the buffer is empty
% also the last 3 entries of temp should be 36

% start the communication
fwrite(cython, start_ch, 'uchar');


for j=1:(1000)

sum_outer=0;
for k=1:50

 temp= fread(cython, packet_bytes);
% Map of the bytes:
% Byte 1 : Header  = 160
% Byte 2 : Sample number
% Bytes 3-5: Data value for EEG channel 1
% Bytes 6-8: Data value for EEG channel 2
% Bytes 9-11: Data value for EEG channel 3
% Bytes 12-14: Data value for EEG channel 4
% Bytes 15-17: Data value for EEG channel 5
% Bytes 18-20: Data value for EEG channel 6
% Bytes 21-23: Data value for EEG channel 6
% Bytes 24-26: Data value for EEG channel 8
% Bytes 27-32: We do not need them, Accelerometer - data 
% Byte 33: Stop byte =192

test1=temp(6);
test2=temp(7);
test3=temp(8);
D1 = de2bi(test1,8,'left-msb');
D2 = de2bi(test2,8,'left-msb');
D3 = de2bi(test3,8,'left-msb');

D=[D1, D2, D3];

% convert to a decimal value using the 2 complement interpretation 
if D(1)==0
sum=0;
else
sum=-1*2^(23);    
end
% Scale Factor to Convert from Counts to Volts 
% derived from ADS1299 data sheet
for i=1:23
    sum=sum+D(i+1)*2^(23-i);
end
voltage=gain*sum;
sum_outer=sum_outer+voltage;
end

avg_voltage(j)=sum_outer/100;
subplot(5,1,1)
plot(100*avg_voltage)

% Detrending the data using best fit line
detrended_data=detrend(avg_voltage);
 title('Raw EEG Signal')
subplot(5,1,2)
plot(100*detrended_data)
title('De-Trended Signal')

% moving average filter to reduce any noise
moving_average_signal=movmean(detrended_data,2);
subplot(5,1,3)
plot(moving_average_signal)
title('After Moving Average Filter')

% moving variance flter for peak detection 
moving_variance_filter=movvar(moving_average_signal,2);
subplot(5,1,4)
plot(10*moving_variance_filter)
title('After Moving Variance Filter')

% converting to 0s and 1s for easier control signal 
converted_signal=0;
for j=1:length(moving_variance_filter)
    if moving_variance_filter(j)<0.005*10^(-7)
    converted_signal(j)=0;
    else
    converted_signal(j)=1;
    end
    subplot(5,1,5)
end
moving_variance_filter;
plot(converted_signal);
title('Converted to 0s and 1s')
%hold on
pause(0.001)
%plot(fread(cython, packet_bytes))
end

fwrite(cython, end_ch, 'uchar');