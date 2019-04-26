
% Mohammad Asif Zaman
% Version 1.3 April 25, 2019

% Vector Field Topology (2D)


% Functions required
% 1. tes_vector_field()   :  If a test vector field is required to be loaded 
% 2. F_diff_mat_2D_v2(.)  :  Load the finite difference matrices
% 3. JacobianInterp(.)    :  A function that evaluates the Jacobian matrix at an arbitrary point
% 4. critical_class(.)    :  Classifies the critical points from corresponding Eigne values
% 5. int_locus(.)         :  Draws the integral lines
% 6. drawArrow(.)         :  Function to draw arrows on the integral lines


clear all;
close all;
clc; clf;



% ======================================================================>>>
% <<<======================================================================



%  Loading the vector field and defining the spatial grid
% ======================================================================>>>

[ux,uy] = test_vector_field();   % Load a test vector field

xL = -3; xU = 3; yL = -2; yU = 2;  % Lower and upper bound of x and y


[Ny,Nx] = size(ux);     % Size of the vector field

x = linspace(xL,xU,Nx); % Defining the space variables from sie of the vector field and the bounds of x and y
y = linspace(yL,yU,Ny);
[X,Y] = meshgrid(x,y);  % Defining the meshgrid


u2 = ux.^2 + uy.^2;     % Squared norm function

quiver(X,Y,ux,uy);
% hold on;
% startx = -3:.5:3;
% starty = -3*ones(size(startx));
% streamline(X,Y,ux,uy,startx,starty);
% startx = -3:.5:3;
% starty = 1*ones(size(startx));
% streamline(X,Y,ux,uy,startx,starty);

figure,
contourf(X,Y,ux,40,'linestyle','none'); colorbar; title('ux'); xlabel('x'); ylabel('y');
figure,
contourf(X,Y,uy,40,'linestyle','none'); colorbar; title('uy'); xlabel('x'); ylabel('y');
figure,
contourf(X,Y,ux.^2 + uy.^2,40,'linestyle','none'); colorbar; title('|u|^2'); xlabel('x'); ylabel('y');

% <<<======================================================================











% Jacobian matrix calculation
% ======================================================================>>>

% The Jacobian matrix is calculated at all points in the grid. This will
% be used as a reference dataset. The Jacobian matrix at an arbitrary point
% in space will be calculated from this dataset using 2D interpolation.

dx = X(1,2) - X(1,1);
dy = Y(2,1) - Y(1,1);


[D2x,D2y,DD2x,DD2y] = F_diff_mat_2D_v2(Ny,Nx);  % Loading the finite difference matrices

J11 = reshape(D2x*ux(:)./(2*dx), size(X));
J12 = reshape(D2y*ux(:)./(2*dy), size(X));
J21 = reshape(D2x*uy(:)./(2*dx), size(X));
J22 = reshape(D2y*uy(:)./(2*dy), size(X));



% figure,
% contourf(X,Y,J11,40,'linestyle','none');
% 
% figure,
% contourf(X,Y,J12,40,'linestyle','none');
% 
% figure,
% contourf(X,Y,J21,40,'linestyle','none');
% 
% figure,
% contourf(X,Y,J22,40,'linestyle','none');


% <<<======================================================================







 
%  Calculating the critical points: April 23, 2019
% ======================================================================>>>
tic
% Find local minima of |u|^2. This will be a good approximate for the zeros
% of [ux uy]' = 0.

counter = 0;
for m = 2:Nx-1
    for n = 2:Ny-1
        if u2(n,m) < u2(n,m-1) & u2(n,m) < u2(n,m+1) & u2(n,m) < u2(n-1,m) & u2(n,m) < u2(n+1,m) 
            counter = counter + 1;
            xc_guess(counter) = X(n,m);
            yc_guess(counter) = Y(n,m);
            xc_ind(counter) = m;
            yc_ind(counter) = n;
          
        end
    end
end



% Verifying whethere the minimas are zeros (global) or local vallies
% This step needs more work
u2min = min(u2(:));

min_tol = 1e-3;   % Defining a threshold value. 
% If the differnece between a minima and the minimum values is smaller than
% this, then the minima is considered a global minima.

counter2 = 0;
for m = 1:length(xc_guess)
    temp = interp2(X,Y,u2,xc_guess(m),yc_guess(m));
    if abs(temp) <= u2min + min_tol
        counter2 = counter2 + 1;
        xc_guess_v(counter2) = xc_guess(m);
        yc_guess_v(counter2) = yc_guess(m);
    end
end


% xc_guess_v = xc_guess;
% yc_guess_v = yc_guess;


% 2D Newton-Raphson method to refine the position of the critical points
% Finding zero of u = [ux uy]' = 0; J = [uxx uxy; uyx uyy]; delta = -J^-1*u
% x_new = x_old + delta

max_iter = 30;      % Maximum number of iterations for the Newton-Raphson method
xy_tol = dx./100;   % Desired accuracy. If delta_x and delta_y are smaller than xy_tol, then Newton-Raphson stops. 


for n_critical = 1:length(xc_guess_v)
    x0 = xc_guess_v(n_critical);
    y0 = yc_guess_v(n_critical);
    
    for iter = 1:max_iter
        ux0 = interp2(X,Y,ux,x0,y0);
        uy0 = interp2(X,Y,uy,x0,y0);
        b = [ux0; uy0];
        J0 = JacobianInterp(J11,J12,J21,J22,X,Y,x0,y0);
        delta = -J0\b;
        
        x0 = x0 + delta(1);
        y0 = y0 + delta(2);
        
        % Break if the values of delta(1) and delta(2) are smaller than the
        % xy_tol.
        if abs(delta(1)) < xy_tol & abs(delta(2)) < xy_tol
            break;
        end
    end
    xc(n_critical) = x0;
    yc(n_critical) = y0;
    
    
end
tcritical = toc;
fprintf('Number of critical points found = %d \n',length(xc));
fprintf('Time required for calculating the critical points = %1.2f sec\n',tcritical);
% <<<======================================================================





% Critical point classification
% ======================================================================>>>

% 1 = att_focus, 2 = rep_focus, 3 = saddle, 4 = center, 5 = att_node
% 6 = rep_node


% Collor array. Associating a different color for each of the critical
% point types.
clr_arr = [0.0   0.4   0.8;
           1.0   0.0   0.0;
           0.0   0.6   0.0;
           1.0   1.0   0.0;
           0.5   0.5   0.5;
           0.8   0.0   0.8;    
                  ];
              
              
txt_arr = {'Att. focus', 'Rep. focus', 'Saddle', 'Center', 'Att. node','Rep. node'};


for m = 1:length(xc)

    temp_J = JacobianInterp(J11,J12,J21,J22,X,Y,xc(m),yc(m));  % Calculating the Jacobian matrix at critical point
    [temp_V,temp_D] = eig(temp_J);  % Calculating the eigen values and eigen vectors
    
    temp_lambda = diag(temp_D);     % Eigen values
    
    cr_clss(m) = critical_class(temp_lambda);  % Classifying the critical points
    
    figure(1); hold on;
    plot(xc(m),yc(m),'Marker','o','MarkerFaceColor',clr_arr(cr_clss(m),:),'markersize',8,'color','none');

end

% <<<======================================================================





% Calculating the integral lines: April 23, 20119
% ======================================================================>>>
tic
xsink = xc(cr_clss == 1 | cr_clss == 5);
ysink = yc(cr_clss == 1 | cr_clss == 5);

cnt = 0;
for m = 1:length(xc)
    
    % Check critical point class. For sinks, the direction has to be
    % reversed (the lines propagate in the opposite direction of the field
    % vector).
    if cr_clss(m) == 1 | cr_clss(m) == 4 | cr_clss(m) == 5
        drct = -1;
    else 
        drct = 1;
    end
    
    
    x0 = xc(m);
    y0 = yc(m);
    J0 = JacobianInterp(J11,J12,J21,J22,X,Y,x0,y0); 
    [temp_V,temp_D] = eig(temp_J);
    
    % Setting the intial direction of the integral lines to be parallel to
    % the eigen vectors.
    xslope_set = [temp_V(1,1) -temp_V(1,1) temp_V(1,2) -temp_V(1,2)];
    yslope_set = [temp_V(2,1) -temp_V(2,1) temp_V(2,2) -temp_V(2,2)];


    
    for eg_vct = 1:length(xslope_set)
        xslope = xslope_set(eg_vct);
        yslope = yslope_set(eg_vct);
        
        
        
        xy_locus = int_locus(X,Y,ux,uy,x0,y0,xslope,yslope,xsink,ysink,drct);
        
        cnt = cnt + 1;
        xlocus{cnt} = xy_locus(:,1);
        ylocus{cnt} = xy_locus(:,2);
        cr_clss_save(cnt) = cr_clss(m);
        
        % For saddle points, draw in +drct and -drct directions. There are
        % redundancies though. For each direction, there are just 2 lines,
        % instead of 4.
        if cr_clss(m) == 3 
                xy_locus = int_locus(X,Y,ux,uy,x0,y0,xslope,yslope,xsink,ysink,-drct);
                cnt = cnt + 1;
                xlocus{cnt} = xy_locus(:,1);
                ylocus{cnt} = xy_locus(:,2);
                cr_clss_save(cnt) = cr_clss(m);
        end
        
    end
    
    fprintf('Finished calculating integral lines for critical point %d \n',m);

end
tlocus = toc;
fprintf('Time required for calculating the integral lines = %1.2f sec\n',tlocus);

% <<<======================================================================





figure(1);
hold on;
for m = 1:length(xlocus)
    plot(xlocus{m},ylocus{m},'k');
    
    drawArrow(xlocus{m},ylocus{m},X,Y,ux,uy,clr_arr(cr_clss_save(m),:));
    
    
end

xlabel('x'); ylabel('y');
axis([xL xU yL yU]);

daspect([1 1 1]);
set(gca,'Position',[0.1 0.1 .65 .65]);


for m = 1:6
    annotation('ellipse',[.82 m/10+.05 .015 .02],'Facecolor',clr_arr(m,:),'color','none');
    annotation('textbox',[.83 m/10+.085 0 0],'string',txt_arr{m});
%      annotation('string','Saddle');
    
end
pbaspect([1 1 1]);








