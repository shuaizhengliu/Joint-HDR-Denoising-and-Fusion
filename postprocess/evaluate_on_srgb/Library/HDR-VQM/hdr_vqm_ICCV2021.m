function HDRVQM = hdr_vqm_ICCV2021(path_src_native,path_hrc_native,path_src_emitted,path_hrc_emitted, cfg_hdrvqm)
% path_src_native: useless
% path_hdr_native: useless
% path_src_emitted: reference hdr
% path_hdr_emitted: distorted hdr

%set the default parameters, run the config file
%config_hdrvqm;
%global cfg_hdrvqm;
switch cfg_hdrvqm.do_adapt
    case ('none')
		fprintf('\nNo display processing requested...\n') 
		pause(1)
		fprintf('\nQuality will be computed assuming that the input data is scaled according to display...\n\n')
    case('linear')
		fprintf('\nProcessing source and distorted videos using linear scaling...\n') 
		pause(1)
		%fprintf('\nScaling factor is determined from the entire sequence (not individual frames).\n') 
		%pause(1)
		fprintf('\nQuality will be computed on the processed sequences.\n\n')
    otherwise
        error('Invalid selection of display processing')
end		
delete(gcp('nocreate'))
%adapt_display_hdrvqm(path_src_native,path_src_emitted,cfg_hdrvqm);
%adapt_display_hdrvqm(path_hrc_native,path_hrc_emitted,cfg_hdrvqm);

Image_Name_src = get_hdr_list(path_src_emitted);
Image_Name_hrc = get_hdr_list(path_hrc_emitted);
if (length(Image_Name_src) < 1)
    error('No groundtruth HDRs found!')
end
if (length(Image_Name_hrc) < 1)
    error('No estimated HDRs found!')
end
if (length(Image_Name_src) ~= length(Image_Name_hrc))
    error('Length of groundtruth does not match the estimated HDRs!')
end
fprintf('Reference/Distorted file number: %d/%d\n', length(Image_Name_src), length(Image_Name_hrc))

%Images_List_HDR_src = dir(fullfile(path_src_emitted, '*.hdr'));
%Images_List_EXR_src = dir(fullfile(path_src_emitted, '*.exr'));
%Images_List_HDR_hrc = dir(fullfile(path_hrc_emitted, '*.hdr'));
%Images_List_EXR_hrc = dir(fullfile(path_hrc_emitted, '*.exr'));
%Images_List_src = [Images_List_HDR_src;Images_List_EXR_src];
%Images_List_hrc = [Images_List_HDR_hrc;Images_List_EXR_hrc];

flag_number_image = numel(Image_Name_src);
switch cfg_hdrvqm.data
    case('image')
        if(flag_number_image<1)
                error('no image detected. Specify video in this case')
        end
    case('video')
        if(flag_number_image<1)
                error('No HDR founds!')
        end
        if(flag_number_image==1)
                error('One image/frame detected. Specify image option in this case')
        end
end



if cfg_hdrvqm.do_parallel_loop
%(optional) use a parallel loop for faster processing
    %matlabpool open 4
    p = parpool('local', 16);
    fprintf('\nComputing quality...\n')			
    parfor frame_count = 1:numel(Image_Name_src)
        src_hdr_path = fullfile(path_src_emitted, Image_Name_src{frame_count});
        est_hdr_path = fullfile(path_hrc_emitted, Image_Name_hrc{frame_count});
        [~, src_hdr_name] = fileparts(src_hdr_path);
        [~, est_hdr_name] = fileparts(est_hdr_path);
        fprintf('%d/%d: %s %s\n', frame_count, numel(Image_Name_src), src_hdr_name, est_hdr_name)
        error_video_hdrvqm(:,:,frame_count) = hdrvqm_perframe_error2(src_hdr_path, est_hdr_path, cfg_hdrvqm);
    end
    switch cfg_hdrvqm.data
        case('image')
            HDRVQM = st_pool(st_pool(error_video_hdrvqm,0.5),0.5);
            fprintf('\nHDR-VQM for image is: %f\n',HDRVQM)
            fprintf('Normalized HDR-VQM for image is: %f\n',4./(1+exp(HDRVQM))-1)
            fprintf('\n')
            clear error_video_hdrvqm
            %matlabpool close force local
            delete(p)
        case('video')
            HDRVQM = hdrvqm_error_pooling(error_video_hdrvqm,cfg_hdrvqm);
            fprintf('\nHDR-VQM for video is: %f\n',HDRVQM)
            fprintf('Normalized HDR-VQM for video is: %f\n',4./(1+exp(HDRVQM))-1)
            fprintf('\n')
            clear error_video_hdrvqm
            delete(p)
            %matlabpool close force local
    end	
    
    
else
    fprintf('\nComputing quality...\n')			
    for frame_count = 1:numel(Image_Name_src)
        src_hdr_path = fullfile(path_src_emitted, Image_Name_src{frame_count});
        est_hdr_path = fullfile(path_hrc_emitted, Image_Name_hrc{frame_count});
        fprintf('%d/%d: %s %s\n', frame_count, numel(Image_Name_src), src_hdr_path, est_hdr_path)
        error_video_hdrvqm(:,:,frame_count) = hdrvqm_perframe_error2(src_hdr_path, est_hdr_path, cfg_hdrvqm);
    end
    switch cfg_hdrvqm.data
        case('image')
            HDRVQM = st_pool(st_pool(error_video_hdrvqm,0.5),0.5);
            fprintf('\nHDR-VQM for image is: %f\n',HDRVQM)
            fprintf('Normalized HDR-VQM for image is: %f\n',4./(1+exp(HDRVQM))-1)
            fprintf('\n')
            clear error_video_hdrvqm
            matlabpool close force local
        case('video')
            HDRVQM = hdrvqm_error_pooling(error_video_hdrvqm,cfg_hdrvqm);
            fprintf('\nHDR-VQM for video is: %f\n',HDRVQM)
            fprintf('Normalized HDR-VQM for video is: %f\n',4./(1+exp(HDRVQM))-1)
            fprintf('\n')
            clear error_video_hdrvqm
    end
end
end
