%%  A Script demonstrating the basic functionalities of the FmapLib (Work in progress).
    clr;
    gitdir;
    cd FmapLib/src

%% Load a Mesh and calculate basic quantities.
    meshfile  = '../data/kid_rodola/0001.isometry.1.off';
    inmesh    = Mesh(meshfile, 'rodola_1_1');
    inmesh.set_triangle_angles();
    inmesh.set_vertex_areas('barycentric');            
    sum(inmesh.get_vertex_areas('barycentric'))             % We don't normalize vertex areas to sum to 1.
        
%     LB             = Laplace_Beltrami(inmesh);              % Calculate the first 100 spectra, based on barycentric vertex areas.
%     [evals, evecs] = LB.get_spectra(100, 'barycentric'); 
%     save('../data/output/mesh_and_LB', 'inmesh', 'LB');
 
    % Load Precomputed ones.
    load('../data/output/mesh_and_LB', 'inmesh', 'LB');
    [evals, evecs] = LB.get_spectra(100, 'barycentric');


    %% Two Meshes and a F-map.
    num_eigs       = 100;
    wks_samples    = 150;
    hks_samples    = 100;
    curvatures     = 100;

    meshfile       = '../data/kid_rodola/0001.isometry.1.off';
    mesh1          = Mesh(meshfile, 'rodola_1_1');        
    LB1            = Laplace_Beltrami(mesh1);    
    [evals, evecs] = LB1.get_spectra(num_eigs, 'barycentric');
    save('../data/output/LB1', 'LB1');          

%     load('../data/output/LB1');    
%     [evals, evecs] = LB1.get_spectra(num_eigs, 'barycentric');

    [energies, sigma] = Mesh_Features.energy_sample_generator('log_linear', evals(2), evals(end), wks_samples);
    wks_sig           = Mesh_Features.wave_kernel_signature(evecs(:,2:end), evals(2:end), energies, sigma);    
    heat_time         = Mesh_Features.energy_sample_generator('log_sampled', evals(2), evals(end), hks_samples);
    hks_sig           = Mesh_Features.heat_kernel_signature(evecs(:,2:end), evals(2:end), heat_time);
    
%     heat_time         = Mesh_Features.energy_sample_generator('log_sampled', evals(2), evals(end), curvatures-1);
%     mean_curvature    = Mesh_Features.mean_curvature(mesh1, LB1, heat_time);    
%     gauss_curvature   = Mesh_Features.gaussian_curvature(mesh1, heat_time);
    
    %TODO-P Normalize prob functions
    from_probes       = LB1.project_functions('barycentric', num_eigs, wks_sig, hks_sig);
 
    meshfile          = '../data/kid_rodola/0002.isometry.1.off';
    mesh2             = Mesh(meshfile, 'rodola_2_1');
    LB2               = Laplace_Beltrami(mesh2);            
    [evals, evecs]    = LB2.get_spectra(num_eigs, 'barycentric');
    save('../data/output/LB2', 'LB2');          
    [energies, sigma] = Mesh_Features.energy_sample_generator('log_linear', evals(2), evals(end), wks_samples);
    wks_sig           = Mesh_Features.wave_kernel_signature(evecs(:,2:end), evals(2:end), energies, sigma);    
    heat_time         = Mesh_Features.energy_sample_generator('log_sampled', evals(2), evals(end), hks_samples);
    hks_sig           = Mesh_Features.heat_kernel_signature(evecs(:,2:end), evals(2:end), heat_time);
    to_probes         = LB2.project_functions('barycentric', num_eigs, wks_sig, hks_sig);    

%     lambda = 20;        
%     X      = Functional_Map.sum_of_squared_frobenius_norms(from_probes, to_probes, LB1.get_spectra(num_eigs, 'barycentric'), LB2.get_spectra(num_eigs, 'barycentric'), lambda); 
%%
    correspondences = [1:mesh1.num_vertices; 1:mesh2.num_vertices]';
    [~, basis_from] = LB1.get_spectra(num_eigs, 'barycentric');
    [~, basis_to]   = LB2.get_spectra(num_eigs, 'barycentric');
    X_opt = Functional_Map.groundtruth_functional_map(basis_from, basis_to, correspondences);

%% 
    groundtruth = (1:mesh1.num_vertices)';
    evaluation_samples  = 20;    
    [dist]              = Functional_Map.pairwise_distortion_of_map(X_opt, mesh1, mesh2, basis_from, basis_to, evaluation_samples, groundtruth);                                          
    
