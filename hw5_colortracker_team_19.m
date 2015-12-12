% COMS4733 HW5 Team 19 Color Tracker
% sap2147 - Skylar Pagenkopf
% rfl2119 - Rich Landy

function hw5_colortracker_team_19(serPort)
    
    % init steps
    [rgb, img] = init();
    target_mask = threshold(rgb, img);
    [prev_area, prev_center, prev_radius] = target_details(target_mask);
    img_center = size(img)/2;
    
    anglet = .2;
    areat = .2;
    angle = 0;
    % loop to see if target has moved
    while (1)
        img = imread('http://192.168.1.103/snapshot.cgi?user=admin&pwd=&resolution=16&rate=0');
        img = imresize(img, .25);
        target_mask = threshold(rgb, img);
        [area, center, radius] = target_details(target_mask);
        
        % couldn't find the object, stop and continue
        if area == 0
            disp('no target');
            SetFwdVelAngVelCreate(serPort, 0, 0);
            continue;
        end
        
        disp(img_center);
        disp(center);
        % rotate left
        if center(1) < (1-anglet)*img_center(2)
            disp('turn left');
            angle = .11;
        % rotate right
        elseif center(1) > (1+anglet)*img_center(2)
            disp('turn right');
            angle = -.11;
        % don't turn
        else
            disp('no turn');
            angle = 0;
        end
        
        % move backward if area is larger
        if area > prev_area*(1+areat)
            disp('backward');
            SetFwdVelAngVelCreate(serPort, -.07, angle);
        % move forward if area is smaller
        elseif area < prev_area*(1-areat)
            disp('forward');
            SetFwdVelAngVelCreate(serPort, .07, angle);
        % stop moving if area is the same
        else
            disp('stop');
            SetFwdVelAngVelCreate(serPort, 0, 0);
        end
        
        % reset variables
        prev_area = area;
        prev_center = center;
        prev_radius = radius;
        
        pause(0.2);
        
        % for testing
        figure(1);
        imshow(img);
        hold on
        viscircles(center,radius);
        hold off
    end
end

% You will initiate the color tracker manually. Take an image and have the user click on
% the image color you want to track. This will give you a threshold range for color
% segmentation.
function [rgb, img] = init()
    img = imread('http://192.168.1.103/snapshot.cgi?user=admin&pwd=&resolution=16&rate=0');
    img = imresize(img, .25);        % find what works best later
    figure(1);
    imshow(img);
    [x,y] = ginput(1);
    rgb = impixel(img,x,y); 
    close(1);
end

% Threshold the image, and find the largest blob in the image which will be your target
% (use a large enough target).
function [mask] = threshold(rgb, img)
    redBand = img(:, :, 1); 
	greenBand = img(:, :, 2); 
	blueBand = img(:, :, 3);
    extra = 30;                 % as long as floor is not red/pink should work
    redThresholdLow = rgb(1)-extra;
    redThresholdHigh = rgb(1)+extra;
    greenThresholdLow = rgb(2)-extra;
    greenThresholdHigh = rgb(2)+extra;
    blueThresholdLow = rgb(3)-extra;
    blueThresholdHigh = rgb(3)+extra;
    mask = (redBand >= redThresholdLow) & (redBand <= redThresholdHigh) & (greenBand >= greenThresholdLow) & (greenBand <= greenThresholdHigh) & (blueBand >= blueThresholdLow) & (blueBand <= blueThresholdHigh);
end

% Calculate the centroid and area of the blob (in pixels)
function [area, center, radius] = target_details(target_mask)
    objs = regionprops(target_mask, 'Area', 'Centroid', 'BoundingBox', 'MajorAxisLength', 'MinorAxisLength');
    area = 0;
    center = [-1,-1];
    for i = 1:size(objs)
        if objs(i).Area > area
            area = objs(i).Area;
            center = objs(i).Centroid;
            diameter = mean([objs(i).MajorAxisLength objs(i).MinorAxisLength],2);
            radius = diameter/2;
        end
    end
end