#!/usr/bin/env python3

# https://raw.githubusercontent.com/ste93ste/freesurfer/nf-estimate2classsedRepresentation/python/freesurfer/samseg/compute2classesAtlasProbabilities.py
import os
import numpy as np
import nibabel as nib
import argparse
from freesurfer import samseg
eps = np.finfo(float).eps

# ------ Parse Command Line Arguments ------

parser = argparse.ArgumentParser()

# required
parser.add_argument('--subjects-dir', metavar='DIR', help='Directory with saved SAMSEG runs with --history flag.', required=True)
parser.add_argument('--segmentations-dir', metavar='DIR', help='Directory with binary manual segmentations.', required=True)
parser.add_argument('--segmentation-name', help='Filename of the segmentations, assumed to be the same for each subject', required=True)
parser.add_argument('--mesh-collections', nargs='+', metavar='FILE', help='Mesh collection file(s).', required=True)
parser.add_argument('--out-dir', help='Output directory', required=True)
# optional
parser.add_argument('--showfigs', action='store_true', default=False, help='Show figures during run.')
args = parser.parse_args()

if not os.path.exists(args.out_dir):
    os.makedirs(args.out_dir)

if args.showfigs:
    visualizer = samseg.initVisualizer(True, True)
else:
    visualizer = samseg.initVisualizer(False, False)

# We need an init of the probabilistic segmentation class
# to call instance methods
atlas = samseg.ProbabilisticAtlas()



level = 0
for meshCollectionFile in args.mesh_collections:

    print("Working on mesh collection at level " + str(level + 1))

    # Read mesh collection
    print("Loading mesh collection at: " + str(meshCollectionFile))
    meshCollection = samseg.gems.KvlMeshCollection()
    meshCollection.read(meshCollectionFile)

    # We are interested only on the reference mesh
    mesh = meshCollection.reference_mesh
    numberOfNodes = mesh.point_count
    #
    subjectList = [o for o in os.listdir(args.subjects_dir) 
                   if os.path.isdir(os.path.join(args.subjects_dir,o))]
    numberOfSubjects = len(subjectList)
    print('Number of subjects: ', numberOfSubjects)
    print('Subejct list:', subjectList)

    # Define what we are interesting in, i.e., the label statistics of lesion
    labelStatisticsInMeshNodes = np.zeros([numberOfNodes, 2, numberOfSubjects])

    subjectNumber = 0
    for subjectDir in subjectList:
      
        # Read the manually annotated binary segmentation for the specific subject
        segmentationImage = nib.load(os.path.join(args.segmentations_dir, subjectDir, args.segmentation_name)).get_fdata()

        history = np.load(os.path.join(args.subjects_dir, subjectDir, 'mri/samseg', 'history.p'), allow_pickle=True)

        # Get the node positions in image voxels
        modelSpecifications = history['input']['modelSpecifications']
        transform_matrix = history['transform']
        transform = samseg.gems.KvlTransform(samseg.requireNumpyArray(transform_matrix))
        deformations = history['historyWithinEachMultiResolutionLevel'][level]['deformation']
        deformationAtlasFileName = history['historyWithinEachMultiResolutionLevel'][level]['deformationAtlasFileName']
        nodePositions = atlas.getMesh(
            meshCollectionFile,
            transform,
            K=modelSpecifications.K,
            initialDeformation=deformations,
            initialDeformationMeshCollectionFileName=meshCollectionFile
        ).points
        # The image is cropped as well so the voxel coordinates
        # do not exactly match with the original image,
        # i.e., there's a shift. Let's undo that.
        cropping = history['cropping']
        nodePositions += [slc.start for slc in cropping]

        # Estimate 2-class alphas representing the segmentation map, initialized with a flat prior
        segmentationMap = np.zeros([segmentationImage.shape[0], segmentationImage.shape[1], segmentationImage.shape[2], 2], np.uint16)
        segmentationMap[:, :, :, 0] = (1 - segmentationImage) * 65535
        segmentationMap[:, :, :, 1] = segmentationImage * 65535
        alphas = np.zeros([numberOfNodes, 2]) + 0.5
        mesh = meshCollection.reference_mesh
        mesh.alphas = alphas
        mesh.points = nodePositions

        for EMIterationNumber in range(20):
            # E-step
            # TODO: return also minLogLikelihood, now we are only printing it in the gems function
            labelStatistics = mesh.collect_label_statistics_nodes(segmentationMap)
            # M-step
            alphas = labelStatistics / (np.expand_dims(np.sum(labelStatistics, axis=1) + eps, 1))
            mesh.alphas = alphas

        # Show rasterized prior with updated alphas
        if args.showfigs:
            rasterizedPrior = mesh.rasterize(segmentationImage.shape, 1) / 65535
            visualizer.show(images=rasterizedPrior)

        # Show progress to anyone who's watching
        print('====================================================================')
        print('')
        print('subjectNumber: ' + str(subjectNumber + 1))
        print('')
        print('====================================================================')

        # Save label statistics of subject
        labelStatisticsInMeshNodes[:, :, subjectNumber] = labelStatistics

        subjectNumber = subjectNumber + 1

    # Save label statistics in a npz file
    np.save(os.path.join(args.out_dir, 'labelStatistics_' + 'atlas_' + str(level)), labelStatisticsInMeshNodes)
    level = level + 1
