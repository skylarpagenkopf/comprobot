% COMS4733 HW5 Team 19 Door Knocker
% sap2147 - Skylar Pagenkopf
% rfl2119 - Rich Landy

function hw5_door_knock(serPort)
    %state 1 - init centered in hallway 
    %state 2 - travelling down hallway, looking for door
    %state 3 - travelling down hallway, door located
    %state 4 - door being bumped
    %state 5 - waiting for open door
    %state 6 - door opened
    %hsv = [132, 151, 145];
    hsv = [0.5444, 0.1200, 0.4902];
    state = 1;
    while state < 6
        state
       if state == 1
          %search for door
          door = findDoor(hsv);
          if ~door
              state = 2;
              SetFwdVelAngVelCreate(serPort, 0.2, 0);
          else
              state = 3;
              SetFwdVelAngVelCreate(serPort, 0.2, door);
          end
       end
       
       if state == 2
            %search for door
            door = findDoor(hsv);
            if door
              state = 3;       
              SetFwdVelAngVelCreate(serPort, 0.2, door);
            end
       end
       
       if state == 3
          [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort);
          if BumpRight || BumpLeft || BumpFront
              state = 4;
              SetFwdVelAngVelCreate(serPort, 0, 0);
              travelDist(serPort, 0.2, -0.5);
              SetFwdVelAngVelCreate(serPort, 0.2, 0);
          else
            door = findDoor(hsv);
            SetFwdVelAngVelCreate(serPort, 0.2, door);
          end
       end
       
       if state == 4
           [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort);
           if BumpRight || BumpLeft || BumpFront
              SetFwdVelAngVelCreate(serPort, 0, 0);
              travelDist(serPort, 0.2, -0.5);
              img = imread('http://192.168.1.103/snapshot.cgi?user=admin&pwd=&resolution=16&rate=0');
              target_mask = threshold(hsv, img);
              [area, center, radius] = target_details(target_mask);
              BeepRoomba(serPort);
              state = 5;
           end
       end
       
       if state == 5
          %wait for door color to no longer be present 
          door = detectDoor(hsv, area);
          if ~door
             travelDist(serPort, 0.2, 1.5);
             state = 6; 
          end
       end
       
       pause(0.2);
    end
end

function [door] = findDoor(hsv) 
    img = imread('http://192.168.1.103/snapshot.cgi?user=admin&pwd=&resolution=16&rate=0');
    [target_mask, img] = threshold(hsv, img);
    [area, center, radius] = target_details(target_mask);
    img_center = size(img)/2;
    anglet = .2;
    
       % for testing
        figure(1);
        imshow(img);
        hold on
        viscircles(center,radius);
        hold off

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
    
    door = angle;
end

function [door] = detectDoor(hsv, orig_area) 
    img = imread('http://192.168.1.103/snapshot.cgi?user=admin&pwd=&resolution=16&rate=0');    
    target_mask = threshold(hsv, img);
    [area, center, radius] = target_details(target_mask);
    door = 1;
    %work on this
    if orig_area/2 > area
       door = 0; 
    end
end

% Threshold the image, and find the largest blob in the image which will be your target
% (use a large enough target).
function [mask, img] = threshold(hsv, img)
    hsv_img = rgb2hsv(img);
    rBand = hsv_img(:, :, 1); 
%     gBand = img(:, :, 2); 
%     bBand = img(:, :, 3); 
    hextra = 0.05;                 % as long as floor is not red/pink should work
    rThresholdLow = hsv(1)-hextra;
    rThresholdHigh = hsv(1)+hextra;
%     gThresholdLow = hsv(2)-hextra;
%     gThresholdHigh = hsv(2)+hextra;    
%     bThresholdLow = hsv(3)-hextra;
%     bThresholdHigh = hsv(3)+hextra;
    mask = (rBand >= rThresholdLow) & (rBand <= rThresholdHigh);
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