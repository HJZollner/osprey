function out = osp_plotCoreg(MRSCont, kk, VoxelIndex)
%% out = osp_plotProcess(MRSCont, kk)
%   Creates a figure showing coregistration between T1 image and MRS voxel
%   stored in an Osprey data container
%
%   USAGE:
%       out = osp_plotCoreg(MRSCont, kk)
%
%   OUTPUTS:
%       out     = MATLAB figure handle
%
%   OUTPUTS:
%       MRSCont  = Osprey data container.
%       kk       = Index for the kk-th dataset (optional. Default = 1)
%       VoxelIndex = Index for DualVoxel (optional. Default = 1)
%
%   AUTHOR:
%       Helge Z�llner (Johns Hopkins University, 2019-11-26)
%       hzoelln2@jhmi.edu
%
%   HISTORY:
%       2019-11-26: First version of the code.

% Check that OspreyCoreg has been run before
if ~MRSCont.flags.didCoreg
    error('Trying to plot coregistration data, but data has not been processed yet. Run OspreyCoreg first.')
end

%%% 1. PARSE INPUT ARGUMENTS %%%
% Fall back to defaults if not provided
if nargin < 3
   VoxelIndex = 1; 
    if nargin < 2
        kk = 1;
        if nargin<1
            error('ERROR: no input Osprey container specified.  Aborting!!');
        end
    end
end

%%% 2. LOAD DATA TO PLOT %%%
% Load T1 image, mask volume, T1 max value, and voxel center
[~,filename_voxel,fileext_voxel]   = fileparts(MRSCont.files{kk});
[~,filename_image,fileext_image]   = fileparts(MRSCont.coreg.vol_image{kk}.fname);
[~,~,fileext_mask]   = fileparts(MRSCont.coreg.vol_mask{kk}.fname);

if ~exist(MRSCont.coreg.vol_image{kk}.fname,'file')
    gunzip([MRSCont.coreg.vol_image{kk}.fname, '.gz']);
end
if ~exist(MRSCont.coreg.vol_mask{kk}.fname,'file')
    gunzip([MRSCont.coreg.vol_mask{kk}.fname, '.gz']);
end

Vimage=spm_vol(MRSCont.coreg.vol_image{kk}.fname);
if ~(isfield(MRSCont.flags,'isPRIAM') && (MRSCont.flags.isPRIAM == 1))
    Vmask=spm_vol(MRSCont.coreg.vol_mask{kk}.fname);    
    voxel_ctr = MRSCont.coreg.voxel_ctr{kk};
else
    Vmask=spm_vol(MRSCont.coreg.vol_mask{kk}{VoxelIndex}.fname);    
    voxel_ctr = MRSCont.coreg.voxel_ctr{kk}(:,:,VoxelIndex); 
end

if ~MRSCont.flags.didSeg
    if exist([MRSCont.coreg.vol_mask{kk}.fname, '.gz'],'file')
        delete(MRSCont.coreg.vol_mask{kk}.fname);
    end
    if exist([MRSCont.coreg.vol_image{kk}.fname, '.gz'],'file')
        delete(MRSCont.coreg.vol_image{kk}.fname);
    end
end
%%% 3. SET UP THREE PLANE IMAGE %%%
% Generate three plane image for the output
% Transform structural image and co-registered voxel mask from voxel to
% world space for output (MM: 180221)
[img_t,img_c,img_s] = voxel2world_space(Vimage,voxel_ctr);
[mask_t,mask_c,mask_s] = voxel2world_space(Vmask,voxel_ctr);

img_t = flipud(img_t/MRSCont.coreg.T1_max{kk});
img_c = flipud(img_c/MRSCont.coreg.T1_max{kk});
img_s = flipud(img_s/MRSCont.coreg.T1_max{kk});

img_t = img_t + 0.225*flipud(mask_t);
img_c = img_c + 0.225*flipud(mask_c);
img_s = img_s + 0.225*flipud(mask_s);

size_max = max([max(size(img_t)) max(size(img_c)) max(size(img_s))]);
three_plane_img = zeros([size_max 3*size_max]);
three_plane_img(:,1:size_max)              = image_center(img_t, size_max);
three_plane_img(:,size_max+(1:size_max))   = image_center(img_s, size_max);
three_plane_img(:,size_max*2+(1:size_max)) = image_center(img_c, size_max);

%%% 4. SET UP FIGURE LAYOUT %%%
% Generate a new figure and keep the handle memorized
if ~MRSCont.flags.isGUI
    out = figure;
    set(gcf, 'Color', 'w');
else
    out = figure('Visible','off');
end

imagesc(three_plane_img);
colormap('gray');
caxis([0 1])
axis equal;
axis tight;
axis off;


if ~(isfield(MRSCont.flags,'isPRIAM') && (MRSCont.flags.isPRIAM == 1))
    titleStr = sprintf(['Coregistration:\n ' filename_voxel fileext_voxel ' & '  filename_image fileext_image]);
else
    titleStr = sprintf(['Coregistration:\n ' filename_voxel fileext_voxel ' & '  filename_image fileext_image '\n Voxel ' num2str(VoxelIndex)]);      
end

if ~MRSCont.flags.isGUI
        title(titleStr, 'Interpreter', 'none','FontSize', 16);
else
    title(titleStr, 'Interpreter', 'none','FontSize', 16,'Color', MRSCont.colormap.Foreground);
end

%%% 5. ADD OSPREY LOGO %%%
if ~MRSCont.flags.isGUI
    [I, map] = imread('osprey.gif','gif');
    axes(out, 'Position', [0, 0.85, 0.15, 0.15*11.63/14.22]);
    imshow(I, map);
    axis off;
end
end

   