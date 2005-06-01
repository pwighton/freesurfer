package require Tix

DebugOutput "\$Id: scuba.tcl,v 1.117 2005/06/01 20:16:03 kteich Exp $"

# gTool
#   current - current selected tool (nav,)

# gaWidget
#   window - main window
#   tkcon - tkcon frame
#   scubaFrame,ID - frame widget for frame ID
#   menuBar - menu bar
#     col, row - grid position
#   toolBar - tool bar
#     col, row - grid position
#   scubaFrame - scuba frame object
#     col, row - grid position
#   labelArea - label area
#     col, row - grid position
#   subjectsLoader
#     subjectsMenu - menu of subjects, value is index gaSubject(nameList)
#     volumeMenu - list of currect subj's mri vols, value is full filename
#     surfaceMenu - list of current subj's surfs, value is full filename
#   layerProperties
#     menu - layer menu, value is layer ID
#   viewProperties
#     menu - view menu, value is view ID
#     drawLevelMenuN - menu of layers at draw level N, value is layer ID
#     transformMenu - menu of transforms, value is transform ID
#   transformProperties
#     menu - transform menu, value is transform ID

# gSubject
#   nameList - directory listing of SUBJECTS_DIR

# gaMenu

# gaSubject

# gaFrame
#   n - id of frame
#     viewConfig
#     toolID

# gaView
#   current
#     id
#     menuIndex
#     id
#     col
#     row
#     linked
#     drawN
#     transformID
#     inPlane

# gaLayer
#   current - currently displayed layer in props panel
#     id
#     type
#     label
#     opacity
#     colorMapMethod  - 2DMRI only
#     sampleMethod - 2DMRI only
#     brightness - 2DMRI only
#     contrast - 2DMRI only
#   idList - list of IDs in layer props listbox

# gaTool
#   n - id of tool
#     mode


set gbDebugOutput false
proc dputs { isMsg } {
    global gbDebugOutput
    if { $gbDebugOutput } {
	puts "scuba: $isMsg"
    }
}


set gNextFrameID 0
proc GetNewFrameID { } {
    dputs "GetNewFrameID   "

    global gNextFrameID
    set frameID $gNextFrameID
    incr gNextFrameID
    return $frameID;
}

proc BuildShortcutDirsList {} {
    dputs "BuildShortcutDirsList  "

    global glShortcutDirs env
    set glShortcutDirs {}
    if { [info exists env(SUBJECTS_DIR)] } {
	lappend glShortcutDirs $env(SUBJECTS_DIR)
    }
    if { [info exists env(FREESURFER_DATA)] } {
	lappend glShortcutDirs $env(FREESURFER_DATA)
    }
    if { [info exists env(FREESURFER_HOME)] } {
	lappend glShortcutDirs $env(FREESURFER_HOME)
    }
    if { [info exists env(PWD)] } {
	lappend glShortcutDirs $env(PWD)
    }
    if { [info exists env(FSDEV_TEST_DATA)] } {
	lappend glShortcutDirs $env(FSDEV_TEST_DATA)
    }
}


proc AddDirToShortcutDirsList { iDir } {
    dputs "AddDirToShortcutDirsList  $iDir  "


    global glShortcutDirs
    foreach dir $glShortcutDirs {
	if { $iDir == $dir } { return }
    }
    lappend glShortcutDirs $iDir
}

proc GetDefaultFileLocation { iType } {
    dputs "GetDefaultFileLocation  $iType  "

    global gsaDefaultLocation 
    global env
    global gSubject
    if { [info exists gsaDefaultLocation($iType)] == 0 } {
	switch $iType {
	    LoadVolume - SaveVolume {
		if { [info exists env(SUBJECTS_DIR)] } {
		    if { [info exists gSubject(homeDir)] } {
			set gsaDefaultLocation($iType) $gSubject(homeDir)/mri
		    } else {
			set gsaDefaultLocation($iType) $env(SUBJECTS_DIR)
		    }
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	    LoadSurface - LoadPatch {
		if { [info exists env(SUBJECTS_DIR)] } {
		    if { [info exists gSubject(homeDir)] } {
			set gsaDefaultLocation($iType) $gSubject(homeDir)/surf
		    } else {
			set gsaDefaultLocation($iType) $env(SUBJECTS_DIR)
		    }
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	    SaveLabel - LoadLabel {
		if { [info exists env(SUBJECTS_DIR)] } {
		    if { [info exists gSubject(homeDir)] } {
			set gsaDefaultLocation($iType) $gSubject(homeDir)/label
		    } else {
			set gsaDefaultLocation($iType) $env(SUBJECTS_DIR)
		    }
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	    Transform {
		if { [info exists env(SUBJECTS_DIR)] } {
		    if { [info exists gSubject(homeDir)] } {
			set gsaDefaultLocation($iType) $gSubject(homeDir)/mri/transforms
		    } else {
			set gsaDefaultLocation($iType) $env(SUBJECTS_DIR)
		    }
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	    LUT {
		if { [info exists env(FREESURFER_HOME)] } {
		    set gsaDefaultLocation($iType) $env(FREESURFER_HOME)
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	    TIFF {
		set gsaDefaultLocation($iType) [exec pwd]
	    }
	    ControlPoints {
		if { [info exists env(SUBJECTS_DIR)] } {
		    if { [info exists gSubject(homeDir)] } {
			set gsaDefaultLocation($iType) $gSubject(homeDir)/tmp
		    } else {
			set gsaDefaultLocation($iType) $env(SUBJECTS_DIR)
		    }
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	    Scene {
		set gsaDefaultLocation($iType) [exec pwd]
	    }
	    default { 
		if { [info exists gSubject(homeDir)] } {
		    set gsaDefaultLocation($iType) $gSubject(homeDir)
		} else {
		    set gsaDefaultLocation($iType) [exec pwd]
		}	       
	    }
	}
    }
    return $gsaDefaultLocation($iType)
}

proc SetDefaultFileLocation { iType isValue } {
    dputs "SetDefaultFileLocation  $iType $isValue  "

    global gsaDefaultLocation
    if { [string range $isValue 0 0] == "/" } {
	set gsaDefaultLocation($iType) $isValue
    }
}

proc SetSubjectName { isSubject } {
    dputs "SetSubjectName  $isSubject  "

    global gSubject
    global gaWidget
    global env
    
    # Make sure this subject exists in the subject directory
    if { ![info exists env(SUBJECTS_DIR)] } { 
	tkuErrorDlog "SUBJECTS_DIR environment variable not set."
	return
    }
    if { ![file isdirectory $env(SUBJECTS_DIR)/$isSubject] } { 
	tkuErrorDlog "Subject $isSubject doesn't exist."
	return
    }

    # Set some info.
    set gSubject(name) $isSubject
    set gSubject(homeDir) [file join $env(SUBJECTS_DIR) $isSubject]
    set gSubject(subjectsDir) $env(SUBJECTS_DIR)

    # Select it in the subjects loader.
    SelectSubjectInSubjectsLoader $isSubject
	
}

proc GetSubjectName {} {
    global gSubject
    if { [info exists gSubject(name)] } {
	return $gSubject(name)
    } else {
	return "No-Subject-Set"
    }
}

proc GetSubjectDir {} {
    global gSubject
    if { [info exists gSubject(homeDir)] } {
	return $gSubject(homeDir)
    } else {
	return "No-Subject-Set"
    }
}

proc FindFile { ifn } {
    dputs "FindFile  $ifn  "

    global gSubject

    set fn $ifn

    # If this is not a full path...
    if { [file pathtype $fn] != "absolute" } {

	# If it's partial, and if we have a subject name...
	if { [info exists gSubject(homeDir)] } {
	    
	    # Check a couple of the common places to find files.
	    lappend lfn [file join $gSubject(homeDir) mri $ifn]
	    lappend lfn [file join $gSubject(homeDir) mri transforms $ifn]
	    lappend lfn [file join $gSubject(homeDir) label $ifn]
	    lappend lfn [file join $gSubject(homeDir) surf $ifn]
	    foreach fnTest $lfn {
		if { [file exists $fnTest] } {
		    set fn $fnTest
		    break
		}
	    }
	}
    }

    
    # Make sure this file exists
    if { [file exists $fn] == 0 } {
	error "Couldn't find file '$fn'"
    }

    # Make sure it is readable
    if { [file readable $fn] == 0 } {
	error "File $fn isn't readable"
    }

    return $fn
}

proc ExtractLabelFromFileName { ifnData } {
    dputs "ExtractLabelFromFileName  $ifnData  "

    global gbDebugOutput

    set sSeparator [string range [file join " " " "] 1 1]

    set sSubject ""
    set sData ""
    set sLabel ""

    # Look for 'subjects' to see if we have a subjects path.
    set bFoundSubjectName 0
    if { [string first subjects $ifnData] != -1 } {

	# First look for subjects. If found
	set nBegin [string first subjects $ifnData]
	set nEnd 0
	if { $nBegin != -1 } {
	    incr nBegin 9   ; #skip past subjects/
	    #look for the next separator
	    set nEnd [string first $sSeparator $ifnData $nBegin]
	    if { $nEnd == -1 } { ; # if / not found, just use the whole rest
		set nEnd [string length $ifnData]
	    } else {
		incr nEnd -1 ; # end is at sep now so go back one
	    }
	    set bFoundSubjectName 1
	} 
    }
    
    # look for a ***/SUBJECTNAME/mri/*** pattern. first look
    # for mri, this-1 will be the end.
    if { ! $bFoundSubjectName } {
	
	set nEnd [string first mri $ifnData]
	if { $nEnd != -1 } {
	    incr nEnd -2 ; # go back to before the separator
	    set nBegin $nEnd ; # go backwards until we hit another sep.
	    while { [string range $ifnData $nBegin $nBegin] != $sSeparator &&
		    $nBegin > 0 } {
		incr nBegin -1
	    }
	    if { $nBegin != 0 } {
		incr nBegin ; # skip seprator
		set bFoundSubjectName 1
	    }
	}
	
    } 
    
    # That's it for subject name.
    if { $bFoundSubjectName } {
	set sSubject [string range $ifnData $nBegin $nEnd]
    } else {
	# still not found, just use nothing.
	set sSubject ""
    }
    
    # Volume data name is between mri/ and the next slash.
    set bFoundDataName 0
    set nBegin [string first mri $ifnData]
    set nEnd 0
    if { $nBegin != -1 } {
	incr nBegin 4
	set nEnd [string first / $ifnData $nBegin]
	if { $nEnd == -1 } {
	    set nEnd [string length $ifnData]
	    set sData [string range $ifnData $nBegin $nEnd]
	    set sData [file rootname $sData] ; # Remove any file suffixes.
	    set bFoundDataName 1
	}
    }

    # Surface data name is after surf/.
    set nBegin [string first surf$sSeparator $ifnData]
    if { $nBegin != -1 } {
	incr nBegin 5
	set sData [string range $ifnData $nBegin end]
	set bFoundDataName 1
    } else {
	
	# Could still be a surface if it has lh. or rh. in the file
	# name. Matches lh.blah or rh.blah.
	set sTest [regexp -inline -all -- {[lr]h\.\w*} $ifnData]
	if { [llength $sTest] > 0 } {
	    set sData $sTest
	    set bFoundDataName 1
	}
    }

    if { ! $bFoundDataName } {
	# Not found, just use file name without suffix and path.
	set sData [file rootname [file tail $ifnData]]
    }
    
    set sLabel [string trimleft [string trimright "$sSubject $sData"]]

    return $sLabel
}

set ksImageDir   "$env(FREESURFER_HOME)/lib/images/"
proc LoadImages {} {
    dputs "LoadImages  "


    global ksImageDir
    
    set sFileErrors ""
    foreach sImageName { icon_edit_label icon_edit_volume icon_draw_line
	icon_navigate icon_rotate_plane icon_edit_ctrlpts 
	icon_edit_parc icon_line_tool
	icon_view_single icon_view_multiple icon_view_31 
	icon_cursor_goto icon_cursor_save 
	icon_main_volume icon_aux_volume icon_linked_cursors 
	icon_arrow_up icon_arrow_down icon_arrow_left icon_arrow_right 
	icon_arrow_cw icon_arrow_ccw 
	icon_arrow_expand_x icon_arrow_expand_y 
	icon_arrow_shrink_x icon_arrow_shrink_y 
	icon_orientation_coronal icon_orientation_horizontal 
	icon_orientation_sagittal 
	icon_zoom_in icon_zoom_out 
	icon_brush_square icon_brush_circle icon_brush_3d 
	icon_surface_main icon_surface_original icon_surface_pial 
	icon_snapshot_save icon_snapshot_load 
	icon_marker_crosshair icon_marker_diamond 
	icon_stopwatch } {

	set fnImage [file join $ksImageDir $sImageName.gif]
	if { [catch {image create photo $sImageName -file $fnImage} \
	      sResult] != 0 } {
	    set sFileErrors "$sFileErrors $fnImage"
	}
    }

    if { $sFileErrors != "" } {
	tkuFormattedErrorDlog "Error Loading Images" \
	    "Couldn't load some images." \
	    "Couldn't find the following images: $sFileErrors"
    }
}


proc MakeMenuBar { ifwTop } {
    dputs "MakeMenuBar  $ifwTop  "

    global gaMenu
    global gaView
    global gaWidget
    
    set fwMenuBar     $ifwTop.fwMenuBar
    set gaMenu(file)  $fwMenuBar.mbwFile
    set gaMenu(edit)  $fwMenuBar.mbwEdit
    set gaMenu(view)  $fwMenuBar.mbwView
    set gaMenu(tools) $fwMenuBar.mbwTools

    frame $fwMenuBar -border 2 -relief raised

    tkuMakeMenu -menu $gaMenu(file) -label "File" -items {
	{command "New Volume..." { DoNewVolumeDlog } }
	{command "Load Volume..." { DoLoadVolumeDlog } }
	{command "Load Surface..." { DoLoadSurfaceDlog } }
	{command "Load Patch Into Surface..." { DoLoadPatchDlog } }
	{command "Save..." { DoSave } }
	{command "Save As..." { DoSaveAsDlog } }
	{command "Save Copy As..." { DoSaveCopyAsDlog } }
	{separator}
	{command "Load Label..." { DoLoadLabelDlog } }
	{command "Save Label..." { DoSaveLabelDlog } }
	{command "Export ROIs as Segmenation..." { DoExportROIsDlog } }
	{separator}
	{command "Load Paths..." { DoLoadPathsDlog } }
	{command "Save Paths..." { DoSavePathsDlog } }
	{separator}
	{command "Load Transform..." { DoLoadTransformDlog } }
	{separator}
	{command "Import Markers from Control Points..."
	    { DoImportMarkersFromControlPointsDlog } }
	{command "Export Markers to Control Points..." 
	    { DoExportMarkersToControlPointsDlog } }
	{separator}
	{command "Save TIFF Capture..." { DoSaveTIFFDlog } }
	{separator}
	{command "Save Scene Setup Script..." { DoSaveSceneSetupScriptDlog } }
	{separator}
	{command "Quit:Alt Q" { Quit } }
    }

    set gaWidget(Menu,fileMenu) $gaMenu(file).mw
    set gaWidget(Menu,fileMenuLoadPatchIndex) 4
    set gaWidget(Menu,fileMenuSaveIndex) 5
    set gaWidget(Menu,fileMenuSaveAsIndex) 6
    set gaWidget(Menu,fileMenuSaveCopyAsIndex) 7

    pack $gaMenu(file) -side left

    tkuMakeMenu -menu $gaMenu(edit) -label "Edit" -items {
	{command "Nothing to undo" 
	    { Undo; RedrawFrame [GetMainFrameID]; UpdateUndoMenuItem } }
	{command "Nothing to redo" 
	    { Redo; RedrawFrame [GetMainFrameID]; UpdateUndoMenuItem } }
	{separator}
	{command "Preferences..." { DoPrefsDlog } }
    }

    pack $gaMenu(edit) -side left

    tkuMakeMenu -menu $gaMenu(view) -label "View" -items {
	{check "Flip Left/Right" { SetViewFlipLeftRightYZ $gaView(current,id) $gaView(flipLeftRight) } gaView(flipLeftRight) }
	{check "Coordinate Overlay" { SetPreferencesValue DrawCoordinateOverlay $gaView(coordOverlay); RedrawFrame [GetMainFrameID] } gaView(coordOverlay) }
	{check "Markers" { SetPreferencesValue DrawMarkers $gaView(markers); RedrawFrame [GetMainFrameID] } gaView(markers) }
	{check "Paths" { SetPreferencesValue DrawPaths $gaView(paths); RedrawFrame [GetMainFrameID] } gaView(paths) }
	{check "Plane Intersections" { SetPreferencesValue DrawPlaneIntersections $gaView(planeIntersections); RedrawFrame [GetMainFrameID] } gaView(planeIntersections) }
	{check "Show Console:Alt N" { ShowHideConsole $gaView(tkcon,visible) } gaView(tkcon,visible) }
	{check "Auto-Configure" {} gaView(autoConfigure) }
	{check "Show FPS" { SetPreferencesValue ShowFPS $gaView(showFPS) } gaView(showFPS) }
    }

    set gaView(flipLeftRight) [GetPreferencesValue ViewFlipLeftRight]
    set gaView(tkcon,visible) [GetPreferencesValue ShowConsole]
    set gaView(coordOverlay)  [GetPreferencesValue DrawCoordinateOverlay]
    set gaView(markers)       [GetPreferencesValue DrawMarkers]
    set gaView(paths)         [GetPreferencesValue DrawPaths]
    set gaView(planeIntersections) [GetPreferencesValue DrawPlaneIntersections]
    set gaView(autoConfigure) [GetPreferencesValue AutoConfigureView]
    set gaView(showFPS)       [GetPreferencesValue ShowFPS]

    pack $gaMenu(view) -side left

    tkuMakeMenu -menu $gaMenu(tools) -label "Tools" -items {
	{command "Histogram Fill..." { MakeHistogramFillWindow } }
	{command "Data Collection Info..." { DoDataInfoWindow } }
	{command "Show Surface Vertex..." { DoShowSurfaceVertex } }
	{command "Find Nearest Surface Vertex..." { DoFindNearestSurfaceVertex } }
	{command "Set Cursor from edit.dat File..." { DoSetCursorFromEditDatFileDlog } }
    }

    pack $gaMenu(tools) -side left

    return $fwMenuBar
}

proc UpdateUndoMenuItem {} {
    global gaMenu

    # Try to get an Undo title. This may fail if there has been no
    # undoable action yet.
    set sLabel "Nothing to undo"
    catch { set sLabel [GetUndoTitle] }

    tkuSetMenuItemName $gaMenu(edit) 1 $sLabel

    set sLabel "Nothing to redo"
    catch { set sLabel [GetRedoTitle] }

    tkuSetMenuItemName $gaMenu(edit) 2 $sLabel
}

proc MakeToolBar { ifwTop } {
    dputs "MakeToolBar  $ifwTop  "

    global gaTool
    global gaFrame
    global gaView
    global gaWidget
    global gCoordsInput

    set fwToolBar     $ifwTop.fwToolBar

    frame $fwToolBar -border 2 -relief raised

    tkuMakeToolbar $fwToolBar.fwTool \
	-allowzero false \
	-radio true \
	-variable gaTool($gaFrame([GetMainFrameID],toolID),mode) \
	-command {ToolBarWrapper} \
	-buttons {
	    { -type image -name navigation -image icon_navigate 
		-balloon "Navigation (n)\nLeft: Pan\nMiddle: Slice\nRight: Zoom\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	    { -type image -name plane -image icon_rotate_plane 
		-balloon "Plane (p)\nLeft: Move center\nMiddle: Rotate plane\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	    { -type image -name marker -image icon_marker_crosshair 
		-balloon "Marker (m)\nLeft: Set cursor\nMiddle: Set marker\nRight: Remove marker\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	    { -type image -name voxelEditing -image icon_edit_volume 
		-balloon "Voxel Editing (e)\nMiddle: Brush with new value\nRight: Erase\nShift-middle: Fill with new value\nShift-right: Fill erase\nShift-ctrl-middle: Get new color\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	    { -type image -name roiEditing -image icon_edit_label 
		-balloon "ROI Editing (r)\nMiddle: Select\nRight: Unselect\nShift-middle: Select file\nShift-right: Unselect fill\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	    { -type image -name straightPath -image icon_line_tool 
		-balloon "Straight Path (s)\n:Left: Start a new path or add a new vertex\nMiddle: Stop making path\nRight: Stop making path and close it\nShift-middle: Select voxels on path\nShift-right: Unselect voxels on path\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	    { -type image -name edgePath -image icon_draw_line 
		-balloon "Edge Path (g)\n:Left: Start a new path or add a new vertex\nMiddle: Stop making path\nRight: Stop making path and close it\nShift-middle: Select voxels on path\nShift-right: Unselect voxels on path\nCtrl-left: Zoom in and recenter\nCtrl-middle: Recenter\nCtrl-right: Zoom out and recenter\nShift-left: Change brightness/contrast" } 
	}

    set gaTool($gaFrame([GetMainFrameID],toolID),mode) navigation

    tkuMakeToolbar $fwToolBar.fwView \
	-allowzero false \
	-radio true \
	-variable gaFrame([GetMainFrameID],viewConfig) \
	-command {ToolBarWrapper} \
	-buttons {
	    { -type image -name c1 -image icon_view_single
		-balloon "Single View" }
	    { -type image -name c22 -image icon_view_multiple
		-balloon "2x2 View" }
	    { -type image -name c13 -image icon_view_31 
		-balloon "1/3 View" }
	}

    set gaFrame([GetMainFrameID],viewConfig) c1

    tkuMakeToolbar $fwToolBar.fwInPlane \
	-allowzero false \
	-radio true \
	-variable gaView(current,inPlane) \
	-command {ToolBarWrapper} \
	-buttons {
	    { -type image -name x -image icon_orientation_sagittal 
		-balloon "X Plane" }
	    { -type image -name y -image icon_orientation_coronal 
		-balloon "Y Plane" }
	    { -type image -name z -image icon_orientation_horizontal 
		-balloon "Z Plane" }
	}

    set gaView(current,inPlane) x

    button $fwToolBar.bwZoomOut  -image icon_zoom_out \
	-command { ZoomViewOut; RedrawFrame [GetMainFrameID] }
    button $fwToolBar.bwZoomIn   -image icon_zoom_in \
	-command { ZoomViewIn; RedrawFrame [GetMainFrameID] }

    frame $fwToolBar.fwCoordsInput -relief raised -border 2
    tkuMakeEntry $fwToolBar.fwCoordsInput.ew \
	-variable gCoordsInput(entry) \
	-command { GotoCoordsInputCallback } \
	-width 16
    set gCoordsInput(entry) "Enter RAS Coords"
    set gaWidget(coordsEntry) $fwToolBar.fwCoordsInput.ew.ewEntry
    bind $gaWidget(coordsEntry) <Button> "after idle {$gaWidget(coordsEntry) selection range 0 end}"
    menubutton $fwToolBar.fwCoordsInput.bw \
	-text "V" \
	-menu $fwToolBar.fwCoordsInput.bw.menu
    set gaWidget(coordsMenuPopup) [menu $fwToolBar.fwCoordsInput.bw.menu]
    $gaWidget(coordsMenuPopup) add command -label "RAS Coords" \
	-command { 
	    set gCoordsInput(system) ras;
	    set gCoordsInput(entry) "Enter RAS Coords";
	    $gaWidget(coordsEntry) selection range 0 end }
    $gaWidget(coordsMenuPopup) add command -label "Index Coords" \
	-command { 
	    set gCoordsInput(system) index;
	    set gCoordsInput(entry) "Enter Index Coords";
	    $gaWidget(coordsEntry) selection range 0 end }
    set gaWidget(coordsMenuButton) $fwToolBar.fwCoordsInput.bw
    pack $fwToolBar.fwCoordsInput.ew $fwToolBar.fwCoordsInput.bw \
	-side left \
	-fill x

    set gCoordsInput(system) ras


    pack $fwToolBar.fwTool $fwToolBar.fwView $fwToolBar.fwInPlane \
	$fwToolBar.bwZoomOut $fwToolBar.bwZoomIn $fwToolBar.fwCoordsInput \
	-side left

    return $fwToolBar
}

proc ToolBarWrapper { isName iValue } {
    dputs "ToolBarWrapper  $isName $iValue  "

    global gaLayer
    global gaFrame
    global gaROI
    global gaTool
    global gaView
    global gaPrefs

    if { $iValue == 1 } {
	switch $isName {
	    navigation - marker - plane - voxelEditing - roiEditing - \
		straightPath - edgePath {
		SetToolMode $gaFrame([GetMainFrameID],toolID) $isName
		SelectToolInToolProperties $isName
		set gaPrefs(SelectedTool) $isName
	    }
	    c1 - c22 - c13 {
		SetFrameViewConfiguration [GetMainFrameID] $isName
		# Customize the views here if requested.
		if { $gaView(autoConfigure) } {
		    set fID [GetMainFrameID]
		    if { "$isName" == "c22" } {
			SetViewInPlane [GetViewIDFromFrameColRow $fID 0 0] x
			SetViewInPlane [GetViewIDFromFrameColRow $fID 1 0] y
			SetViewInPlane [GetViewIDFromFrameColRow $fID 0 1] z
			SetViewInPlane [GetViewIDFromFrameColRow $fID 1 1] x
		    }
		    if { "$isName" == "c13" } {
			SetViewInPlane [GetViewIDFromFrameColRow $fID 0 0] x
			SetViewInPlane [GetViewIDFromFrameColRow $fID 0 1] x
			SetViewInPlane [GetViewIDFromFrameColRow $fID 1 1] y
			SetViewInPlane [GetViewIDFromFrameColRow $fID 2 1] z
		    }
		}
		CopyViewLayersToAllViewsInFrame $fID $gaView(current,id) 
		UpdateViewList
	    }
	    x - y - z {
		SetViewInPlane [GetSelectedViewID [GetMainFrameID]] $isName
		set gaView(current,throughPlaneInc) \
   	 [GetViewThroughPlaneIncrement $gaView(current,id) $isName]
		RedrawFrame [GetMainFrameID]
	    }
	    grayscale - heatScale - lut {
		Set2DMRILayerColorMapMethod \
		    $gaLayer(current,id) $gaLayer(current,colorMapMethod)

		# Preset the Draw 0 Clear cb.
		if { "$isName" == "lut" } {
		    set gaLayer(current,clearZero) 1
		    Set2DMRILayerDrawZeroClear $gaLayer(current,id) 1
		} else {
		    set gaLayer(current,clearZero) 0
		    Set2DMRILayerDrawZeroClear $gaLayer(current,id) 0
		}

		RedrawFrame [GetMainFrameID]
	    }
	    nearest - trilinear - sinc - magnitude {
		Set2DMRILayerSampleMethod \
		    $gaLayer(current,id) $gaLayer(current,sampleMethod)
		RedrawFrame [GetMainFrameID]
	    }
	    structure - free {
		SetROIType $gaROI(current,id) $gaROI(current,type)
		RedrawFrame [GetMainFrameID]
	    }
	    voxel - circle - square {
		SetToolBrushShape $gaFrame([GetMainFrameID],toolID) \
		    $gaTool(current,brushShape)
	    }
	    seed - gradient { 
		SetToolFloodFuzzinessType $gaFrame([GetMainFrameID],toolID) \
		    $gaTool(current,fuzzinessType)
	    }
	    table - user {
		SortVoxelEditingStructureListBox
	    }
	}
    }
}

proc MakeTaskArea { ifwTop } {
    dputs "MakeTaskArea  $ifwTop  "

    global gaFrame
    global gaTask

    set fwTask     $ifwTop.fwTask

    frame $fwTask -border 2 -relief raised

    set ewLabel     $fwTask.ewLabel
    set ewProgress  $fwTask.ewProgress
    set fwButtons   $fwTask.fwButtons

    tkuMakeActiveLabel $ewLabel \
	-font [tkuNormalFont] \
	-variable gaTask(label) -width 50
    tkuMakeActiveLabel $ewProgress \
	-font [tkuNormalFont] \
	-variable gaTask(progress) -width 10
    frame $fwButtons

    set gaTask(buttonFrame) $fwButtons

    # Make our button frame and five dummy buttons. Leave them
    # unpacked now. Later we'll configure and pack them as needed.
    pack $gaTask(buttonFrame)
    button $gaTask(buttonFrame).bw0
    button $gaTask(buttonFrame).bw1
    button $gaTask(buttonFrame).bw2
    button $gaTask(buttonFrame).bw3
    button $gaTask(buttonFrame).bw4

    pack $ewLabel $ewProgress -side left -anchor w
    pack $fwButtons -side right -anchor e


    set gaTask(label) "Ready."

    return $fwTask
}

proc GetMainFrameID {} {

    global gFrameWidgetToID
    global gaWidget
    if { ![info exists gaWidget(scubaFrame)] } {
	return 0
    }
    return $gFrameWidgetToID($gaWidget(scubaFrame))
}

proc MakeScubaFrame { ifwTop } {
    dputs "MakeScubaFrame  $ifwTop  "

    global gFrameWidgetToID
    global gaFrame
    global gaTool
    global gaWidget

    set fwScuba $ifwTop.fwScuba
    
    set frameID [GetNewFrameID]
    togl $fwScuba -width 512 -height 512 -rgba true -ident $frameID

    bind $fwScuba <Motion> \
	"%W MouseMotionCallback %x %y %b; ScubaMouseMotionCallback %x %y %s %b"
    bind $fwScuba <ButtonPress> \
	"%W MouseDownCallback %x %y %b; ScubaMouseDownCallback %x %y %s %b"
    bind $fwScuba <ButtonRelease> \
	"%W MouseUpCallback %x %y %b; ScubaMouseUpCallback %x %y %s %b"
    bind $fwScuba <KeyRelease> \
	"%W KeyUpCallback %x %y %K; ScubaKeyUpCallback %x %y %s %K"
    bind $fwScuba <KeyPress> \
	"%W KeyDownCallback %x %y %K; ScubaKeyDownCallback %x %y %s %K"
    bind $fwScuba <Enter> "focus $fwScuba"

    set gaWidget(scubaFrame,$frameID) $fwScuba
    set gFrameWidgetToID($fwScuba) $frameID

    set gaFrame($frameID,toolID) [GetToolIDForFrame $frameID]
    set gaTool($frameID,mode) [GetToolMode $gaFrame($frameID,toolID)]

    return $fwScuba
}

proc MakeScubaFrameBindings { iFrameID } {
    dputs "MakeScubaFrameBindings  $iFrameID  "

    global gaWidget
    global gaPrefs

    set fwScuba $gaWidget(scubaFrame,$iFrameID)

    bind $fwScuba <Key-1> {set gaTool(current,radius) 1; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) } 
    bind $fwScuba <Key-2> {set gaTool(current,radius) 2; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-3> {set gaTool(current,radius) 3; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-4> {set gaTool(current,radius) 4; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-5> {set gaTool(current,radius) 5; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-6> {set gaTool(current,radius) 6; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-7> {set gaTool(current,radius) 7; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-8> {set gaTool(current,radius) 8; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }
    bind $fwScuba <Key-9> {set gaTool(current,radius) 9; SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius) }

    bind $fwScuba <Key-n> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) navigation };
    bind $fwScuba <Key-p> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) plane };
    bind $fwScuba <Key-m> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) marker };
    bind $fwScuba <Key-e> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) voxelEditing };
    bind $fwScuba <Key-r> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) roiEditing };
    bind $fwScuba <Key-s> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) straightPath };
    bind $fwScuba <Key-g> { set gaTool($gaFrame([GetMainFrameID],toolID),mode) edgePath };
}

proc ScubaMouseMotionCallback { inX inY iState iButton } {
    dputs "ScubaMouseMotionCallback  $inX $inY $iState $iButton  "

    global gaChangeBC
    global gaFrame
    global gaLayer
    global gaTool
    global gaWidget

    # state 257 = mouse 1 + shift. Change the brightness or contrast.
    if { $iState == 257 } {

	set deltaX [expr $inX - $gaChangeBC(mouseDown,x)]
	set deltaY [expr $inY - $gaChangeBC(mouseDown,y)]
	set deltaBrightness 0
	set deltaContrast 0
	if { [expr abs($deltaX) > abs($deltaY)] } {
	    set deltaBrightness [expr -$deltaX / 512.0]
	} else {
	    set deltaContrast [expr $deltaY / 512.0 * 30.0]
	}

	foreach layerID $gaLayer(idList) {
	    if { [GetLayerType $layerID] == "2DMRI" } {
		if { $deltaContrast != 0 } {
		    Set2DMRILayerContrast $layerID \
	     [expr $gaChangeBC($layerID,origContrast) + $deltaContrast]
		}
		if { $deltaBrightness != 0 } {
		    Set2DMRILayerBrightness $layerID \
	     [expr $gaChangeBC($layerID,origBrightness) + $deltaBrightness]
		}
		if { $layerID == $gaLayer(current,id) } {
		    set gaLayer(current,brightness) \
			[Get2DMRILayerBrightness $layerID]
		    set gaLayer(current,contrast) \
			[Get2DMRILayerContrast $layerID]
		}
	    }
	    RedrawFrame [GetMainFrameID]
	}
    }

    # Update the mouse area.
    set err [catch { 
	set viewID [GetViewIDAtFrameLocation [GetMainFrameID] $inX $inY] 
    } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return }

    set err [catch { 
	set labelValues [GetLabelValuesSet $viewID mouse] 
	UpdateLabelArea $gaWidget(labelArea,nMouseArea) $labelValues
    } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return }
}

proc ScubaMouseDownCallback { inX inY iState iButton } {
    dputs "ScubaMouseDownCallback  $inX $inY $iState $iButton  "

    global gaView
    global gaTool
    global gaChangeBC
    global gaFrame
    global gaLayer

    # If button 1 and if shift is down, set up the change brightness
    # contrast tool.
    if { $iButton == 1 && $iState == 1 } {

	set gaChangeBC(viewID) \
	    [GetViewIDAtFrameLocation [GetMainFrameID] $inX $inY] 
	set gaChangeBC(mouseDown,x) $inX
	set gaChangeBC(mouseDown,y) $inY
	foreach layerID $gaLayer(idList) {
	    if { [GetLayerType $layerID] == "2DMRI" } {
		set gaChangeBC($layerID,origBrightness) \
		    [Get2DMRILayerBrightness $layerID]
		set gaChangeBC($layerID,origContrast) \
		    [Get2DMRILayerContrast $layerID]
	    }
	}
    }

    set viewID [GetSelectedViewID [GetMainFrameID]]
    if { $viewID != $gaView(current,id) } {
	SelectViewInViewProperties $viewID
    }

    UpdateUndoMenuItem
}

proc ScubaMouseUpCallback { inX inY iState iButton } {
    dputs "ScubaMouseUpCallback  $inX $inY $iState $iButton  "

    global gaWidget

    UpdateUndoMenuItem

    UpdateCursorLabelArea
}

proc ScubaKeyUpCallback { inX inY iState iKey } {
    
    global gaPrefs
    global gaWidget
    global gaView

    # Check for the mouse key equivs.
    foreach {sKey nButton} {
	KeyMouseButtonOne   1
	KeyMouseButtonTwo   2
	KeyMouseButtonThree 3 } {
	if { [string tolower "$iKey"] == [string tolower "$gaPrefs($sKey)"] } {
	    $gaWidget(scubaFrame,0) MouseUpCallback $inX $inY $nButton
	}
    }

    if { "$iKey" == "$gaPrefs(KeyInPlaneX)" } {
	set gaView(current,inPlane) x
    }
    if { "$iKey" == "$gaPrefs(KeyInPlaneY)" } {
	set gaView(current,inPlane) y
    }
    if { "$iKey" == "$gaPrefs(KeyInPlaneZ)" } {
	set gaView(current,inPlane) z
    }

    if { "$iKey" == "$gaPrefs(KeyCycleViewsInFrame)" } {
	CycleCurrentViewInFrame [GetMainFrameID]
	set viewID [GetSelectedViewID [GetMainFrameID]]
	SelectViewInViewProperties $viewID
	RedrawFrame [GetMainFrameID]
    }

    # This is the view shuffle code. It should probaby be put into its
    # own little funtion, eh.
    if { "$iKey" == "$gaPrefs(KeyShuffleLayers)" } {
	set viewID [GetSelectedViewID [GetMainFrameID]]
	set nHighestLevel 0
	for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {
	    set curLayer($nLevel) [GetLayerInViewAtLevel $viewID $nLevel]
	    if { $curLayer($nLevel) != -1 } {
		set nHighestLevel $nLevel
	    }
	}

	for { set nLevel 0 } { $nLevel <= $nHighestLevel } { incr nLevel } {
	    if { $gaView(current,lockedShuffle$nLevel) } {
		continue
	    }

	    set nNextLevel [expr $nLevel+1]
	    if { $nNextLevel > $nHighestLevel } { set nNextLevel 0 }
	    while { $gaView(current,lockedShuffle$nNextLevel) } {
		incr nNextLevel
		if { $nNextLevel > $nHighestLevel } { set nNextLevel 0 }
		if { $nNextLevel == $nLevel } {
		    return
		}
	    }

	    SetLayerInViewAtLevel $viewID $curLayer($nNextLevel) $nLevel
	}

	SelectViewInViewProperties $viewID

	# Also select the layer that's now on the top level.
	SelectLayerInLayerProperties \
	    [GetLayerInViewAtLevel $viewID $nHighestLevel]
    }

    # This is kind of arbitrary, but since some keypresses can change
    # the information that should be displayed in the label area,
    # update here.
    set viewID [GetSelectedViewID [GetMainFrameID]]

    set err [catch { 
	set labelValues [GetLabelValuesSet $viewID mouse] } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return }

    UpdateLabelArea $gaWidget(labelArea,nMouseArea) $labelValues
}

proc ScubaKeyDownCallback { inX inY iState iKey } {
    
    global gaPrefs
    global gaWidget
    
    # Check for the mouse key equivs.
    foreach {sKey nButton} {
	KeyMouseButtonOne   1
	KeyMouseButtonTwo   2
	KeyMouseButtonThree 3 } {
	if { "$iKey" == "$gaPrefs($sKey)" } {
	$gaWidget(scubaFrame,0) MouseDownCallback $inX $inY $nButton
	    ScubaMouseDownCallback $inX $inY $iState $nButton
	}
    }
}

proc GotoCoordsInputCallback {} {

    global gaView
    global gCoordsInput
    global gaTool
    global gaWidget

    # Get the input string.
    set sCoords $gCoordsInput(entry)

    # [-+]? matches the leading - or +
    # \d+ matches a series of digits like 12
    # \d+\.\d+ matches floating point numbers like 12.34
    set sFiltered [regexp -inline -all -- {[-+]?\d+|[-+]?\d+\.\d+} $sCoords]

    # Make sure we have three elements.
    if { [llength $sFiltered] != 3 } {
	tkuErrorDlog "Invalid coordinate string. Make sure there are three numbers."

    } else {

	if { "$gCoordsInput(system)" == "ras" } {
	    
	    # Set the cursor.
	    SetViewRASCursor [lindex $sFiltered 0] [lindex $sFiltered 1] \
		[lindex $sFiltered 2]
	    RedrawFrame [GetMainFrameID]
	    
	    UpdateCursorLabelArea

	    set gCoordsInput(entry) "Enter RAS Coords"
	    $gaWidget(coordsEntry) selection range 0 end

	} elseif { "$gCoordsInput(system)" == "index" } {

	    if { $gaTool(current,targetLayer) < 0 } {
		tkuErrorDlog "Please specify a target volume layer."
		$gaWidget(coordsEntry) selection range 0 end
		return;
	    }

	    if { [GetLayerType $gaTool(current,targetLayer)] != "2DMRI" } {
		tkuErrorDlog "A volume layer must be targetted."
		$gaWidget(coordsEntry) selection range 0 end
		return;
	    }

	    # Transform coords and set cursor.
	    set lRAS [Get2DMRIRASCoordsFromIndex $gaTool(current,targetLayer) \
			  [lindex $sFiltered 0] [lindex $sFiltered 1] \
			  [lindex $sFiltered 2]]
	    SetViewRASCursor \
		[lindex $lRAS 0] [lindex $lRAS 1] [lindex $lRAS 2]
	    RedrawFrame [GetMainFrameID]
 
	    UpdateCursorLabelArea

	    set gCoordsInput(entry) "Enter Index Coords"
	    $gaWidget(coordsEntry) selection range 0 end
	} else {
	    puts "UH OH"
	}
    }
}

proc GetPreferences {} {
    global gaPrefs
    global gaTool

    foreach sKey {
	KeyInPlaneX
	KeyInPlaneY
	KeyInPlaneZ
	KeyCycleViewsInFrame
	KeyShuffleLayers
	KeyMoveViewLeft
	KeyMoveViewRight
	KeyMoveViewUp 
	KeyMoveViewDown 
	KeyMoveViewIn 
	KeyMoveViewOut
	KeyZoomViewIn 
	KeyZoomViewOut
	KeyMouseButtonOne
	KeyMouseButtonTwo
	KeyMouseButtonThree
	LockOnCursor
	SelectedTool
    } {
	set gaPrefs($sKey) [GetPreferencesValue $sKey]
    }

    # Ready the user structure list.
    set lUserStructureList [GetPreferencesValue UserStructureList]
    foreach {nStructure count} $lUserStructureList {
	set gaTool(structureListOrder,count,$nStructure) $count
    }
}

proc SetPreferences {} {
    global gaPrefs
    global gaTool

    foreach sKey {
	KeyInPlaneX
	KeyInPlaneY
	KeyInPlaneZ
	KeyCycleViewsInFrame
	KeyMoveViewLeft
	KeyMoveViewRight
	KeyMoveViewUp 
	KeyMoveViewDown 
	KeyMoveViewIn 
	KeyMoveViewOut
	KeyZoomViewIn 
	KeyZoomViewOut
	KeyMouseButtonOne
	KeyMouseButtonTwo
	KeyMouseButtonThree
	LockOnCursor
	SelectedTool
    } {
	SetPreferencesValue $sKey $gaPrefs($sKey)
    }

    # Write the user structure list.
    set lUserStructureList {}
    set cStructures [GetColorLUTNumberOfEntries $gaTool(current,voxelLutID)]
    for { set nStructure 0 } { $nStructure < $cStructures } { incr nStructure } {
	if { [info exists gaTool(structureListOrder,count,$nStructure)] } {
	    lappend lUserStructureList $nStructure $gaTool(structureListOrder,count,$nStructure)
	}
    }
    SetPreferencesValue UserStructureList \"$lUserStructureList\"

}

proc Quit {} {
    dputs "Quit  "
    global gaView
    global gaWidget
    
    # Set our prefs values and save our prefs.
    SetPreferencesValue ViewFlipLeftRight $gaView(flipLeftRight)
    SetPreferencesValue ShowConsole $gaView(tkcon,visible)
    SetPreferencesValue DrawCoordinateOverlay $gaView(coordOverlay)
    SetPreferencesValue DrawMarkers $gaView(markers)
    SetPreferencesValue DrawPaths $gaView(paths)
    SetPreferencesValue DrawPlaneIntersections $gaView(planeIntersections)
    SetPreferencesValue AutoConfigureView $gaView(autoConfigure)
    SetPreferencesValue ShowFPS $gaView(showFPS)
    SetPreferences
    SaveGlobalPreferences
    
    # Keep us from doing this multiple times because of binding
    # Quit to the destroy event.
    bind  $gaWidget(window) <Destroy> ""
    destroy $gaWidget(window)

    exit
}

# INTERFACE CREATION ==================================================

proc MakeLabelArea { ifwTop } {
    dputs "MakeLabelArea  $ifwTop  "

    global gaWidget

    set fwLabelArea    $ifwTop.fwLabelArea1

    frame $fwLabelArea

    set fwLabelArea1     $fwLabelArea.fwLabelArea1
    set lwLabelArea1     $fwLabelArea.lwLabelArea1
    set fwLabelArea2     $fwLabelArea.fwLabelArea2
    set lwLabelArea2     $fwLabelArea.lwLabelArea2

    tkuMakeNormalLabel $lwLabelArea1 -label "Cursor" -font [tkuLabelFont]
    tkuMakeNormalLabel $lwLabelArea2 -label "Mouse"  -font [tkuLabelFont]

    set gaWidget(labelArea,1) [frame $fwLabelArea1 -border 2 -relief raised]
    set gaWidget(labelArea,2) [frame $fwLabelArea2 -border 2 -relief raised]

    grid $lwLabelArea1 -column 0 -row 0 -sticky ew
    grid $fwLabelArea1 -column 0 -row 1 -sticky ew
    grid $lwLabelArea2 -column 1 -row 0 -sticky ew
    grid $fwLabelArea2 -column 1 -row 1 -sticky ew

    grid columnconfigure $fwLabelArea 0 -weight 1
    grid columnconfigure $fwLabelArea 1 -weight 1

    set gaWidget(labelArea,1,labelValueWidgets) {}
    set gaWidget(labelArea,1,numberOfLabels) 0
    set gaWidget(labelArea,2,labelValueWidgets) {}
    set gaWidget(labelArea,2,numberOfLabels) 0

    set gaWidget(labelArea,nCursorArea) 1
    set gaWidget(labelArea,nMouseArea) 2

    return $fwLabelArea
}

proc MakeNavigationArea { ifwTop } {
    dputs "MakeNavigationArea  $ifwTop  "

    global gaWidget

    set fwNavArea $ifwTop.fwNavArea
    set fwPan     $fwNavArea.fwPan
    set fwPlane   $fwNavArea.fwPlane
    set fwCenter  $fwNavArea.fwCenter
    set fwInPlane $fwCenter.fwInPlane
    set fwZoom    $fwNavArea.fwZoom
    
    frame $fwNavArea

    frame $fwPan
    button $fwPan.bwUp    -image icon_arrow_up -command { MoveUp }
    button $fwPan.bwDown  -image icon_arrow_down -command { MoveDown }
    button $fwPan.bwLeft  -image icon_arrow_left -command { MoveLeft }
    button $fwPan.bwRight -image icon_arrow_right -command { MoveRight }
    grid $fwPan.bwUp    -column 1 -row 0
    grid $fwPan.bwDown  -column 1 -row 2
    grid $fwPan.bwLeft  -column 0 -row 1
    grid $fwPan.bwRight -column 2 -row 1

    frame $fwPlane
    button $fwPlane.bwIn   -image icon_arrow_up -command { MoveIn }
    button $fwPlane.bwOut  -image icon_arrow_down -command { MoveOut }

    pack $fwPan

    return $fwNavArea
}

proc MakeSubjectsLoaderPanel { ifwTop } {
    dputs "MakeSubjectsLoaderPanel  $ifwTop  "

    global gaWidget
    global gaSubject

    set fwTop  $ifwTop.fwSubjects
    set fwData $fwTop.fwData

    frame $fwTop

    frame $fwData -relief ridge -border 2

    tixOptionMenu $fwData.fwMenu \
	-label "Subject:" \
	-variable gaSubject(current,menuIndex) \
	-command { SubjectsLoaderSubjectMenuCallback }
    set gaWidget(subjectsLoader,subjectsMenu) $fwData.fwMenu

    grid $fwData.fwMenu  -column 0 -row 0 -columnspan 2 -sticky new

    tixOptionMenu $fwData.volumesMenu \
	-label "Volumes:"
    set gaWidget(subjectsLoader,volumeMenu) $fwData.volumesMenu

    button $fwData.volumesButton \
	-text "Load" \
	-command {LoadVolumeFromSubjectsLoader [$gaWidget(subjectsLoader,volumeMenu) cget -value]}

    grid $fwData.volumesMenu   -column 0 -row 1 -sticky new
    grid $fwData.volumesButton -column 1 -row 1 -sticky ne


    tixOptionMenu $fwData.surfacesMenu \
	-label "Surfaces:"
    set gaWidget(subjectsLoader,surfaceMenu) $fwData.surfacesMenu

    button $fwData.surfacesButton \
	-text "Load" \
	-command {LoadSurfaceFromSubjectsLoader [$gaWidget(subjectsLoader,surfaceMenu) cget -value]}
    
    grid $fwData.surfacesMenu   -column 0 -row 2 -sticky new
    grid $fwData.surfacesButton -column 1 -row 2 -sticky ne


    tixOptionMenu $fwData.transformsMenu \
	-label "Transforms:"
    set gaWidget(subjectsLoader,transformMenu) $fwData.transformsMenu

    button $fwData.transformsButton \
	-text "Load" \
	-command {LoadTransform [$gaWidget(subjectsLoader,transformMenu) cget -value]}
    
    grid $fwData.transformsMenu     -column 0 -row 3 -sticky new
    grid $fwData.transformsButton   -column 1 -row 3 -sticky ne


    grid columnconfigure $fwData 0 -weight 1
    grid columnconfigure $fwData 1 -weight 0
    
    grid $fwData -column 0 -row 0 -sticky news

    grid columnconfigure $fwTop 0 -weight 1
    grid rowconfigure $fwTop 0 -weight 1

   return $fwTop
}

proc MakePropertiesPanel { ifwTop } {
    dputs "MakePropertiesPanel  $ifwTop  "

    global gaPanel
    global gaWidget

    set fwTop  $ifwTop.fwProps

    frame $fwTop
    set fwButtons  $fwTop.fwButtons
    set fwPanels   $fwTop.fwPanels
    
    frame $fwButtons -relief raised -border 2

    tkuMakeToolbar $fwButtons.tbwPanelsTop \
	-allowzero 1 -radio 1 \
	-variable gaPanel(currentTop) \
	-command PanelBarWrapper \
	-buttons {
	    {-type text -name subjectsLoader -label "Subjects"}
	    {-type text -name viewProperties -label "Views"}
	    {-type text -name layerProperties -label "Layers"}
	    {-type text -name toolProperties -label "Tools"}
	}
    tkuMakeToolbar $fwButtons.tbwPanelsBottom \
	-allowzero 1 -radio 1 \
	-variable gaPanel(currentBottom) \
	-command PanelBarWrapper \
	-buttons {
	    {-type text -name collectionProperties -label "Data"}
	    {-type text -name transformProperties -label "Transforms"}
	    {-type text -name lutProperties -label "Color LUTs"}
	}
    
    pack $fwButtons.tbwPanelsTop $fwButtons.tbwPanelsBottom -side top \
	-fill x -expand yes -anchor n
    
    frame $fwPanels 

    grid [frame $fwPanels.fwPanel] -column 0 -row 0 -sticky news
    
    grid columnconfigure $fwPanels 0 -weight 1
    grid rowconfigure $fwPanels 0 -weight 1

    set gaWidget(collectionProperties) \
	[MakeDataCollectionsPropertiesPanel $fwPanels.fwPanel]
    set gaWidget(layerProperties) \
	[MakeLayerPropertiesPanel $fwPanels.fwPanel]
    set gaWidget(viewProperties) \
	[MakeViewPropertiesPanel $fwPanels.fwPanel]
    set gaWidget(subjectsLoader) \
	[MakeSubjectsLoaderPanel $fwPanels.fwPanel]
    set gaWidget(transformProperties) \
	[MakeTransformsPanel $fwPanels.fwPanel]
    set gaWidget(lutProperties) \
	[MakeLUTsPanel $fwPanels.fwPanel]
    set gaWidget(toolProperties) \
	[MakeToolsPanel $fwPanels.fwPanel]

    set gaPanel(currentTop) subjectsLoader
    PanelBarWrapper subjectsLoader 1

    grid $fwButtons -column 0 -row 0 -sticky new
    grid $fwPanels -column 0 -row 1 -sticky news
    
    grid rowconfigure $fwTop 0 -weight 0
    grid rowconfigure $fwTop 1 -weight 1

    return $fwTop
}

proc PanelBarWrapper { isName iValue } {
    dputs "PanelBarWrapper  $isName $iValue  "

    global gaPanel
    global gaWidget

    if { $iValue == 0 } {
	pack forget $gaWidget($isName)
    }
    if { $iValue == 1 } {
	pack $gaWidget($isName) -fill both -expand yes -anchor n
	switch $isName {
	    subjectsLoader - viewProperties - 
	    layerProperties - toolProperties {
		set gaPanel(currentBottom) ""
	    }
	    collectionProperties - transformProperties - lutProperties {
		set gaPanel(currentTop) ""
	    }
	}
    }
}

proc MakeDataCollectionsPropertiesPanel { ifwTop } {
    dputs "MakeDataCollectionsPropertiesPanel  $ifwTop  "

    global gaWidget
    global gaCollection
    global gaROI
    global glShortcutDirs

    set fwTop        $ifwTop.fwCollectionsProps
    set fwProps      $fwTop.fwProps
    set fwROIs       $fwTop.fwROIs
    set fwCommands   $fwTop.fwCommands

    frame $fwTop

    frame $fwProps -relief ridge -border 2
    set fwMenu         $fwProps.fwMenu
    set fwPropsCommon  $fwProps.fwPropsCommon
    set fwPropsVolume  $fwProps.fwPropsVolume
    set fwPropsSurface $fwProps.fwPropsSurface

    tixOptionMenu $fwMenu \
	-label "Data Collection:" \
	-variable gaCollection(current,menuIndex) \
	-command { CollectionPropertiesMenuCallback }
    set gaWidget(collectionProperties,menu) $fwMenu

    frame $fwPropsCommon
    tkuMakeActiveLabel $fwPropsCommon.ewID \
	-variable gaCollection(current,id) -width 2
    tkuMakeActiveLabel $fwPropsCommon.ewType \
	-variable gaCollection(current,type) -width 10
    tkuMakeEntry $fwPropsCommon.ewLabel \
	-variable gaCollection(current,label) \
	-command {SetCollectionLabel $gaCollection(current,id) $gaCollection(current,label); UpdateCollectionList} \
	-notify 1
    set gaWidget(collectionProperties,labelEntry) $fwPropsCommon.ewLabel

    tixOptionMenu $fwPropsCommon.mwTransform \
	-label "Transform:" \
	-variable gaCollection(current,transformID) \
	-command "CollectionPropertiesTransformMenuCallback"
    set gaWidget(collectionProperties,transformMenu) \
	$fwPropsCommon.mwTransform
    
    grid $fwPropsCommon.ewID       -column 0 -row 0               -sticky nw
    grid $fwPropsCommon.ewType     -column 1 -row 0               -sticky new
    grid $fwPropsCommon.ewLabel    -column 0 -row 1 -columnspan 2 -sticky we
    grid $fwPropsCommon.mwTransform -column 0 -row 2 -columnspan 2 -sticky we


    frame $fwPropsVolume
    tkuMakeFileSelector $fwPropsVolume.fwVolume \
	-variable gaCollection(current,fileName) \
	-text "Volume file name:" \
	-shortcutdirs [list $glShortcutDirs] \
	-command {SetVolumeCollectionFileName $gaCollection(current,id) $gaCollection(current,fileName); RedrawFrame [GetMainFrameID]}
    
    grid $fwPropsVolume.fwVolume -column 0 -row 0 -sticky ew
    set gaWidget(collectionProperties,volume) $fwPropsVolume

    tkuMakeCheckboxes $fwPropsVolume.cb \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Use RAS Transform" 
		-variable gaCollection(current,useDataToIndexTransform)
		-command { SetUseVolumeDataToIndexTransform $gaCollection(current,id) $gaCollection(current,useDataToIndexTransform) }}
	    {-type text -label "Autosave" 
		-variable gaCollection(current,autosave)
		-command { SetVolumeAutosaveOn $gaCollection(current,id) $gaCollection(current,autosave) }}
	}

    grid $fwPropsVolume.cb -column 0 -row 1 -sticky ew

    frame $fwPropsSurface
    tkuMakeFileSelector $fwPropsSurface.fwSurface \
	-variable gaCollection(current,fileName) \
	-text "Surface file name:" \
	-shortcutdirs [list $glShortcutDirs] \
	-command {SetSurfaceCollectionFileName $gaCollection(current,id) $gaCollection(current,fileName); RedrawFrame [GetMainFrameID]}
    
    grid $fwPropsSurface.fwSurface -column 0 -row 0 -sticky ew
    set gaWidget(collectionProperties,surface) $fwPropsSurface

    tkuMakeCheckboxes $fwPropsSurface.cbTransformFromVolume \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Set RAS Transform from Volume" 
		-variable gaCollection(current,surfaceTransformFromVolume)
		-command { SetSurfaceTransformVolume; UpdateTransformList }}
	}

    grid $fwPropsSurface.cbTransformFromVolume -column 0 -row 1 -sticky ew

    tixOptionMenu $fwPropsSurface.owTransformVolume \
	-label "Volume:" \
	-variable gaTransform(current,surfaceTransformVolume) \
	-command { SurfaceTransformVolumeMenuCallback }
    set gaWidget(collectionProperties,surfaceTransformMenu) \
	$fwPropsSurface.owTransformVolume

    

    grid $fwPropsSurface.owTransformVolume -column 0 -row 2 -sticky ew


    frame $fwROIs -relief ridge -border 2
    tixOptionMenu $fwROIs.menu \
	-label "Current ROI:" \
	-variable gaROI(current,menuIndex) \
	-command { ROIPropertiesMenuCallback }
    set gaWidget(roiProperties,menu) $fwROIs.menu

    tkuMakeActiveLabel $fwROIs.ewID \
	-variable gaROI(current,id) -width 2
    tkuMakeEntry $fwROIs.ewLabel \
	-variable gaROI(current,label) \
	-command {SetROILabel $gaROI(current,id) $gaROI(current,label); UpdateROIList} \
	-notify 1
    set gaWidget(roiProperties,labelEntry) $fwROIs.ewLabel

    tkuMakeToolbar $fwROIs.tbwType \
	-allowzero 0 -radio 1 \
	-variable gaROI(current,type) \
	-command ToolBarWrapper \
	-buttons {
	    {-type text -name free -label "Free"}
	    {-type text -name structure -label "Structure"}
	}
    
    tixOptionMenu $fwROIs.mwLUT \
	-label "LUT:" \
	-command "ROIPropertiesLUTMenuCallback"
    set gaWidget(roiProperties,lutMenu) $fwROIs.mwLUT

    tixScrolledListBox $fwROIs.lbStructure \
	-scrollbar auto \
	-browsecmd ROIPropertiesStructureListBoxCallback
   $fwROIs.lbStructure subwidget listbox configure -selectmode single
   set gaWidget(roiProperties,structureListBox) $fwROIs.lbStructure

    tkuMakeActiveLabel $fwROIs.ewStructure \
	-variable gaROI(current,structureLabel)
    
   
    # hack, necessary to init color pickers first time
    set gaROI(current,redColor) 0
    set gaROI(current,greenColor) 0
    set gaROI(current,blueColor) 0
    
    tkuMakeColorPickers $fwROIs.cpFree \
	-pickers {
	    {-label "Free Color:" 
		-redVariable   gaROI(current,redColor) 
		-greenVariable gaROI(current,greenColor)
		-blueVariable  gaROI(current,blueColor)
		-command {SetROIColor $gaROI(current,id) $gaROI(current,redColor) $gaROI(current,greenColor) $gaROI(current,blueColor); RedrawFrame [GetMainFrameID]}}
	}
    set gaWidget(roiProperties,freeColor) $fwROIs.cpFree

    grid $fwROIs.menu        -column 0 -columnspan 2 -row 0 -sticky new
    grid $fwROIs.ewID        -column 0 -row 1   -sticky nw
    grid $fwROIs.ewLabel     -column 1 -row 1   -sticky new
    grid $fwROIs.tbwType     -column 0 -columnspan 2 -row 2   -sticky new
    grid $fwROIs.mwLUT       -column 0 -columnspan 2 -row 3   -sticky new
    grid $fwROIs.lbStructure -column 0 -columnspan 2 -row 4   -sticky news
    grid $fwROIs.ewStructure -column 0 -columnspan 2 -row 5   -sticky new
    grid $fwROIs.cpFree      -column 0 -columnspan 2 -row 6   -sticky new

    grid columnconfigure $fwROIs 0 -weight 0
    grid columnconfigure $fwROIs 1 -weight 1

    # To make sure the structure list resizes with the window.
    grid rowconfigure $fwROIs 4 -weight 1


    frame $fwCommands
    button $fwCommands.bwMakeROI -text "Make New ROI" \
	-command { set roiID [NewCollectionROI $gaCollection(current,id)]; SetROILabel $roiID "New ROI"; UpdateROIList; SelectROIInROIProperties $roiID }
    pack $fwCommands.bwMakeROI -expand yes -fill x


    grid $fwMenu        -column 0 -row 0 -sticky news
    grid $fwPropsCommon -column 0 -row 1 -sticky news

    grid $fwProps    -column 0 -row 1 -sticky news
    grid $fwROIs     -column 0 -row 3 -sticky news
    grid $fwCommands -column 0 -row 4 -sticky news

    # To make sure the structure list resizes with the window.
    grid rowconfigure $fwTop 3 -weight 1

    return $fwTop
}

proc MakeToolsPanel { ifwTop } {
    dputs "MakeToolsPanel  $ifwTop  "

    global gaWidget
    global gaTool
    global gaView
    global glShortcutDirs

    set fwTop        $ifwTop.fwToolsProps
    set fwProps      $fwTop.fwProps

    frame $fwTop

    frame $fwProps -relief ridge -border 2

    set fwMenu               $fwProps.fwMenu
    set fwPropsCommon        $fwProps.fwPropsCommon
    set fwPropsBrush         $fwProps.fwPropsBrush
    set fwPropsFill          $fwProps.fwPropsFill
    set fwPropsMarker        $fwProps.fwPropsMarker
    set fwPropsVoxelEditing  $fwProps.fwPropsVoxelEditing
    set fwPropsEdgePath      $fwProps.fwPropsEdgePath

    tixOptionMenu $fwMenu \
	-label "Tools:" \
	-variable gaTool(current,menuIndex) \
	-command { ToolPropertiesMenuCallback }
    set gaWidget(toolProperties,menu) $fwMenu

    FillMenuFromList $fwMenu \
	{ navigation plane marker voxelEditing roiEditing straightPath edgePath }  "" \
	{ "Navigation" "Plane" "Marker" "Voxel Editing" "ROI Editing" "Straight Path" "Edge Path"} false


    frame $fwPropsCommon

    tixOptionMenu $fwPropsCommon.owLayer \
	-label "Target Layer:" \
	-variable gatool(current,targetLayer) \
	-command { ToolTargetLayerMenuCallback }
    set gaWidget(toolProperties,targetLayerMenu) $fwPropsCommon.owLayer

    grid $fwPropsCommon.owLayer -column 0 -row 0 -sticky ew


    tixLabelFrame $fwPropsBrush \
	-label "Brush Options" \
	-labelside acrosstop \
	-options { label.padX 5 }

    set fwPropsBrushSub [$fwPropsBrush subwidget frame]
    
    tkuMakeToolbar $fwPropsBrushSub.tbwBrushShape \
	-allowzero false \
	-radio true \
	-variable gaTool(current,brushShape) \
	-command { ToolBarWrapper } \
	-buttons {
	    {-type text -name voxel -label "Voxel"}
	    {-type text -name circle -label "Circle"}
	    {-type text -name square -label "Square"}
	}

    tkuMakeSliders $fwPropsBrushSub.swRadius -sliders {
	{-label "Radius" -variable gaTool(current,radius) 
	    -min 1.0 -max 20 -entry true
	    -resolution 1.0
	    -command {SetToolBrushRadius $gaFrame([GetMainFrameID],toolID) $gaTool(current,radius)} }
    }
    set gaWidget(toolProperties,radiusSlider) $fwPropsBrushSub.swRadius

    tkuMakeCheckboxes $fwPropsBrushSub.cb \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Only brush zero values" 
		-variable gaTool(current,onlyBrushZero)
		-command {SetToolOnlyBrushZero $gaFrame([GetMainFrameID],toolID) $gaTool(current,onlyBrushZero)}}
	}

    grid $fwPropsBrushSub.tbwBrushShape -column 0 -row 0 -sticky ew
    grid $fwPropsBrushSub.swRadius      -column 0 -row 1 -sticky ew
    grid $fwPropsBrushSub.cb          -column 0 -row 2 -sticky ew

    set gaWidget(toolProperties,brush) $fwPropsBrush


    tixLabelFrame $fwPropsFill \
	-label "Fill Options" \
	-labelside acrosstop \
	-options { label.padX 5 }

    set fwPropsFillSub [$fwPropsFill subwidget frame]

    tixOptionMenu $fwPropsFillSub.owSourceCollection \
	-label "Source Data:" \
	-variable gatool(current,floodSourceCollection) \
	-command { ToolFloodSourceCollectionMenuCallback }
    set gaWidget(toolProperties,floodSourceCollectionMenu) $fwPropsFillSub.owSourceCollection

    tkuMakeCheckboxes $fwPropsFillSub.cbFillOptions \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Stop at other ROIs" 
		-variable gaTool(current,stopROI)
		-command {SetToolFloodStopAtROIs $gaFrame([GetMainFrameID],toolID) $gaTool(current,stopROI)}}
	    {-type text -label "Stop at paths" 
		-variable gaTool(current,stopPaths)
		-command {SetToolFloodStopAtPaths $gaFrame([GetMainFrameID],toolID) $gaTool(current,stopPaths)}}
	}
    
    tkuMakeSliders $fwPropsFillSub.swFuzziness -sliders {
	{-label "Fill Fuzziness" -variable gaTool(current,fuzziness) 
	    -min 0 -max 50 -entry true
	    -command {SetToolFloodFuzziness $gaFrame([GetMainFrameID],toolID) $gaTool(current,fuzziness)}}
	{-label "Fill Max Distance" -variable gaTool(current,maxDistance) 
	    -min 0 -max 100 -entry true
	    -command {SetToolFloodMaxDistance $gaFrame([GetMainFrameID],toolID) $gaTool(current,maxDistance)}}
    }

    tkuMakeToolbar $fwPropsFillSub.tbwFuzzinessType \
	-allowzero false \
	-radio true \
	-variable gaTool(current,fuzzinessType) \
	-command { ToolBarWrapper } \
	-buttons {
	    {-type text -name seed -label "Seed"}
	    {-type text -name gradient -label "Gradient"}
	}

    tkuMakeCheckboxes $fwPropsFillSub.cb3D \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Work in 3D" 
		-variable gaTool(current,flood3D)
		-command {SetToolFlood3D $gaFrame([GetMainFrameID],toolID) $gaTool(current,flood3D)}}
	}

    tkuMakeCheckboxes $fwPropsFillSub.cbOnlyFloodZero \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Only fill zero values" 
		-variable gaTool(current,onlyFloodZero)
		-command {SetToolOnlyFloodZero $gaFrame([GetMainFrameID],toolID) $gaTool(current,onlyFloodZero)}}
	}

    grid $fwPropsFillSub.owSourceCollection -column 0 -row 0 -sticky ew
    grid $fwPropsFillSub.cbFillOptions      -column 0 -row 1 -sticky ew
    grid $fwPropsFillSub.swFuzziness        -column 0 -row 2 -sticky ew
    grid $fwPropsFillSub.tbwFuzzinessType   -column 0 -row 3 -sticky ew
    grid $fwPropsFillSub.cb3D               -column 0 -row 4 -sticky ew
    grid $fwPropsFillSub.cbOnlyFloodZero    -column 0 -row 5 -sticky ew

    set gaWidget(toolProperties,fill) $fwPropsFill


    tixLabelFrame $fwPropsMarker \
	-label "Marker Options" \
	-labelside acrosstop \
	-options {label.padX 5}

    set fwPropsMarkerSub [$fwPropsMarker subwidget frame]
    
    tkuMakeEntry $fwPropsMarkerSub.ewNumMarkers \
	-label "Number of Markers" \
	-width 3 \
	-font [tkuNormalFont] \
	-variable gaView(numMarkers) \
	-command {SetNumberOfViewMarkers $gaView(numMarkers) } \
	-notify 1
    set gaWidget(toolProperties,numMarkersEntry) $fwPropsMarkerSub.ewNumMarkers

    grid $fwPropsMarkerSub.ewNumMarkers          -column 0 -row 0 -sticky ew

    set gaWidget(toolProperties,marker) $fwPropsMarker


    tixLabelFrame $fwPropsVoxelEditing \
	-label "Voxel Editing Options" \
	-labelside acrosstop \
	-options {label.padX 5}

    set fwPropsVoxelEditingSub [$fwPropsVoxelEditing subwidget frame]
 
    tkuMakeEntry $fwPropsVoxelEditingSub.ewNewValue \
	-label "New Value" \
	-width 5 \
	-font [tkuNormalFont] \
	-variable gaTool(current,newVoxelValue) \
	-command { SetToolNewVoxelValue $gaTool(current,id) $gaTool(current,newVoxelValue) } \
	-notify 1
    set gaWidget(toolProperties,newVoxelValueEntry) \
	$fwPropsVoxelEditingSub.ewNewValue


    tixOptionMenu $fwPropsVoxelEditingSub.mwLUT \
	-label "LUT:" \
	-command "VoxelEditingLUTMenuCallback"
    set gaWidget(toolProperties,voxelLutMenu) $fwPropsVoxelEditingSub.mwLUT

    tkuMakeEntry $fwPropsVoxelEditingSub.ewEraseValue \
	-label "Erase Value" \
	-width 5 \
	-font [tkuNormalFont] \
	-variable gaTool(current,eraseVoxelValue) \
	-command { SetToolEraseVoxelValue $gaTool(current,id) $gaTool(current,eraseVoxelValue) } \
	-notify 1
    set gaWidget(toolProperties,eraseVoxelValueEntry) \
	$fwPropsVoxelEditingSub.ewEraseValue

    frame $fwPropsVoxelEditingSub.fwStructureListOrder
    tkuMakeNormalLabel $fwPropsVoxelEditingSub.fwStructureListOrder.lwSort \
	-label "Sort: "
    tkuMakeToolbar $fwPropsVoxelEditingSub.fwStructureListOrder.tbwSort \
	-allowzero 0 -radio 1 \
	-variable gaTool(structureListOrder,type) \
	-command ToolBarWrapper \
	-buttons {
	    {-type text -name table -label "Table"}
	    {-type text -name user -label "User"}
	}
    pack $fwPropsVoxelEditingSub.fwStructureListOrder.lwSort \
	$fwPropsVoxelEditingSub.fwStructureListOrder.tbwSort \
	-side left -fill x
    set gaTool(structureListOrder,type) table
    
    tixScrolledListBox $fwPropsVoxelEditingSub.lbStructure \
	-scrollbar auto \
	-browsecmd VoxelEditingStructureListBoxCallback
    $fwPropsVoxelEditingSub.lbStructure subwidget listbox \
	configure -selectmode single
    set gaWidget(toolProperties,voxelStructureListBox) \
	$fwPropsVoxelEditingSub.lbStructure

    button $fwPropsVoxelEditingSub.bwClear \
	-command { ClearUserStructureList } \
	-text "Clear User List" \
	-font [tkuSmallFont]
    
    grid $fwPropsVoxelEditingSub.ewNewValue    -column 0 -row 0 -sticky ew
    grid $fwPropsVoxelEditingSub.mwLUT         -column 0 -row 1 -sticky ew
    grid $fwPropsVoxelEditingSub.fwStructureListOrder \
	-column 0 -row 2 -sticky ew
    grid $fwPropsVoxelEditingSub.lbStructure   -column 0 -row 3 -sticky news
    grid $fwPropsVoxelEditingSub.bwClear       -column 0 -row 4 -sticky ew
    grid $fwPropsVoxelEditingSub.ewEraseValue  -column 0 -row 5 -sticky ew

    # These are to make sure the structure list resizes with the
    # window.
    grid rowconfigure $fwPropsVoxelEditingSub 3 -weight 1
    grid rowconfigure $fwProps 4 -weight 1

    set gaWidget(toolProperties,voxelEditing) $fwPropsVoxelEditing



    tixLabelFrame $fwPropsEdgePath \
	-label "Edge Path Options" \
	-labelside acrosstop \
	-options {label.padX 5}

    set fwPropsEdgePathSub [$fwPropsEdgePath subwidget frame]
    
    tkuMakeSliders $fwPropsEdgePathSub.swEdgeBias -sliders {
	{ -label "Edge Bias" -variable gaTool(current,edgeBias)
	    -min 0 -max 1 -resolution 0.1
	    -command {SetToolEdgePathEdgeBias $gaTool(current,id) $gaTool(current,edgeBias)} }
    }
	

    set gaWidget(toolProperties,edgePathBias) $fwPropsEdgePathSub.swEdgeBias

    grid $fwPropsEdgePathSub.swEdgeBias -column 0 -row 0 -sticky ew

    set gaWidget(toolProperties,edgePath) $fwPropsEdgePath


    grid $fwMenu        -column 0 -row 0 -sticky news
    grid $fwPropsCommon -column 0 -row 1 -sticky news

    grid $fwProps    -column 0 -row 0 -sticky news

    grid columnconfigure $fwTop 0 -weight 1
    grid rowconfigure $fwTop 0 -weight 1

    return $fwTop
}


proc MakeLayerPropertiesPanel { ifwTop } {
    dputs "MakeLayerPropertiesPanel  $ifwTop  "

    global gaWidget
    global gaLayer
    global glShortcutDirs

    set fwTop        $ifwTop.fwLayerProps
    set fwProps      $fwTop.fwProps

    frame $fwTop

    frame $fwProps -relief ridge -border 2
    set fwMenu        $fwProps.fwMenu
    set fwPropsCommon $fwProps.fwPropsCommon
    set fwProps2DMRI  $fwProps.fwProps2DMRI
    set fwProps2DMRIS $fwProps.fwProps2DMRIS

    tixOptionMenu $fwMenu \
	-label "Layer:" \
	-variable gaLayer(current,menuIndex) \
	-command { LayerPropertiesMenuCallback }
    set gaWidget(layerProperties,menu) $fwMenu


    frame $fwPropsCommon
    tkuMakeActiveLabel $fwPropsCommon.ewID \
	-variable gaLayer(current,id) -width 2
    tkuMakeActiveLabel $fwPropsCommon.ewType \
	-variable gaLayer(current,type) -width 5
    tkuMakeEntry $fwPropsCommon.ewLabel \
	-variable gaLayer(current,label) \
	-command {SetLayerLabel $gaLayer(current,id) $gaLayer(current,label); UpdateLayerList} \
	-notify 1
    set gaWidget(layerProperties,labelEntry) $fwPropsCommon.ewLabel
    tkuMakeSliders $fwPropsCommon.swOpacity -sliders {
	{-label "Opacity" -variable gaLayer(current,opacity) 
	    -min 0 -max 1 -resolution 0.1
	    -command {SetLayerOpacity $gaLayer(current,id) $gaLayer(current,opacity); RedrawFrame [GetMainFrameID]}}
    }

    grid $fwPropsCommon.ewID      -column 0 -row 0               -sticky nw
    grid $fwPropsCommon.ewType    -column 1 -row 0               -sticky new
    grid $fwPropsCommon.ewLabel   -column 0 -row 1 -columnspan 2 -sticky we
    grid $fwPropsCommon.swOpacity -column 0 -row 2 -columnspan 2 -sticky we


    frame $fwProps2DMRI
    tkuMakeToolbar $fwProps2DMRI.tbwColorMapMethod \
	-allowzero 0 -radio 1 \
	-variable gaLayer(current,colorMapMethod) \
	-command ToolBarWrapper \
	-buttons {
	    {-type text -name grayscale -label "Grayscale"}
	    {-type text -name heatScale -label "Heat scale"}
	    {-type text -name lut -label "LUT"}
	}

    tixOptionMenu $fwProps2DMRI.mwLUT \
	-label "LUT:" \
	-command "LayerPropertiesLUTMenuCallback"
    set gaWidget(layerProperties,lutMenu) \
	$fwProps2DMRI.mwLUT

    tkuMakeToolbar $fwProps2DMRI.tbwSampleMethod \
	-allowzero 0 -radio 1 \
	-variable gaLayer(current,sampleMethod) \
	-command ToolBarWrapper \
	-buttons {
	    {-type text -name nearest -label "Nearest"}
	    {-type text -name trilinear -label "Trilinear"}
	    {-type text -name sinc -label "Sinc"}
	    {-type text -name magnitude -label "Mag"}
	}
    tkuMakeCheckboxes $fwProps2DMRI.cbwClearZero \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Draw 0 values clear" 
		-variable gaLayer(current,clearZero) 
		-command {Set2DMRILayerDrawZeroClear $gaLayer(current,id) $gaLayer(current,clearZero); RedrawFrame [GetMainFrameID]} }
	}
    tkuMakeSliders $fwProps2DMRI.swBC -sliders {
	{-label "Brightness" -variable gaLayer(current,brightness) 
	    -min 1 -max 0 -resolution 0.01 -entry 1
	    -command {Set2DMRILayerBrightness $gaLayer(current,id) $gaLayer(current,brightness); RedrawFrame [GetMainFrameID]}}
	{-label "Contrast" -variable gaLayer(current,contrast) 
	    -min 0 -max 30 -resolution 1 -entry 1
	    -command {Set2DMRILayerContrast $gaLayer(current,id) $gaLayer(current,contrast); RedrawFrame [GetMainFrameID]}}
    }
    tkuMakeSliders $fwProps2DMRI.swMinMax -sliders {
	{-label "Min" -variable gaLayer(current,minVisibleValue) 
	    -min 0 -max 1 -entry 1 -entrywidth 6
	    -command {Set2DMRILayerMinVisibleValue $gaLayer(current,id) $gaLayer(current,minVisibleValue); RedrawFrame [GetMainFrameID]}}
	{-label "Max" -variable gaLayer(current,maxVisibleValue) 
	    -min 0 -max 1 -entry 1 -entrywidth 6
	    -command {Set2DMRILayerMaxVisibleValue $gaLayer(current,id) $gaLayer(current,maxVisibleValue); RedrawFrame [GetMainFrameID]}}
    }
    set gaWidget(layerProperties,minMaxSliders) $fwProps2DMRI.swMinMax

    tkuMakeCheckboxes $fwProps2DMRI.cbwEditableROI \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Editable ROI" 
		-variable gaLayer(current,editableROI) 
		-command {Set2DMRILayerEditableROI $gaLayer(current,id) $gaLayer(current,editableROI)} }
	}

    tkuMakeSliders $fwProps2DMRI.swROIOpacity -sliders {
	{-label "ROI Opacity" -variable gaLayer(current,roiOpacity) 
	    -min 0 -max 1 -resolution 0.1 
	    -command {Set2DMRILayerROIOpacity $gaLayer(current,id) $gaLayer(current,roiOpacity); RedrawFrame [GetMainFrameID]}}
    }


    grid $fwProps2DMRI.tbwColorMapMethod -column 0 -row 0 -sticky ew
    grid $fwProps2DMRI.mwLUT             -column 0 -row 1 -sticky ew
    grid $fwProps2DMRI.cbwClearZero      -column 0 -row 2 -sticky ew
    grid $fwProps2DMRI.tbwSampleMethod   -column 0 -row 3 -sticky ew
    grid $fwProps2DMRI.swBC              -column 0 -row 4 -sticky ew
    grid $fwProps2DMRI.swMinMax          -column 0 -row 5 -sticky ew
    grid $fwProps2DMRI.cbwEditableROI    -column 0 -row 6 -sticky ew
    grid $fwProps2DMRI.swROIOpacity      -column 0 -row 7 -sticky ew
    set gaWidget(layerProperties,2DMRI) $fwProps2DMRI

    # hack, necessary to init color pickers first time
    set gaLayer(current,redLineColor) 0
    set gaLayer(current,greenLineColor) 0
    set gaLayer(current,blueLineColor) 0

    frame $fwProps2DMRIS
    tkuMakeColorPickers $fwProps2DMRIS.cpLineColors \
	-pickers {
	    {-label "Line Color" -redVariable gaLayer(current,redLineColor) 
		-greenVariable gaLayer(current,greenLineColor)
		-blueVariable gaLayer(current,blueLineColor)
		-command {Set2DMRISLayerLineColor $gaLayer(current,id) $gaLayer(current,redLineColor) $gaLayer(current,greenLineColor) $gaLayer(current,blueLineColor); RedrawFrame [GetMainFrameID]}}
	}
    set gaWidget(layerProperties,lineColorPickers) \
	$fwProps2DMRIS.cpLineColors

    set gaLayer(current,redVertexColor) 0
    set gaLayer(current,greenVertexColor) 0
    set gaLayer(current,blueVertexColor) 0
    tkuMakeColorPickers $fwProps2DMRIS.cpVertexColors \
	-pickers {
	    {-label "Vertex Color" 
		-redVariable gaLayer(current,redVertexColor) 
		-greenVariable gaLayer(current,greenVertexColor)
		-blueVariable gaLayer(current,blueVertexColor)
		-command {Set2DMRISLayerVertexColor $gaLayer(current,id) $gaLayer(current,redVertexColor) $gaLayer(current,greenVertexColor) $gaLayer(current,blueVertexColor); RedrawFrame [GetMainFrameID]}}
	}
    set gaWidget(layerProperties,vertexColorPickers) \
	$fwProps2DMRIS.cpVertexColors

    grid $fwProps2DMRIS.cpLineColors     -column 0 -row 1 -sticky ew
    grid $fwProps2DMRIS.cpVertexColors   -column 0 -row 2 -sticky ew
    set gaWidget(layerProperties,2DMRIS) $fwProps2DMRIS


    grid $fwMenu        -column 0 -row 0 -sticky news
    grid $fwPropsCommon -column 0 -row 1 -sticky news

    grid $fwProps -column 0 -row 0 -sticky news

    grid columnconfigure $fwTop 0 -weight 1
    grid rowconfigure $fwTop 0 -weight 1

   return $fwTop
}

proc MakeViewPropertiesPanel { ifwTop } {
    dputs "MakeViewPropertiesPanel  $ifwTop  "

    global gaWidget
    global gaView

    set fwTop        $ifwTop.fwViewProps
    set fwProps      $fwTop.fwProps

    frame $fwTop


    frame $fwProps -relief ridge -border 2
    set fw1 $fwProps.fw1
    set fw2 $fwProps.fw2
    set fw3 $fwProps.fw3
    set fw4 $fwProps.fw4
    set fw5 $fwProps.fw5
    set fw6 $fwProps.fw6
    set fw7 $fwProps.fw7
    

    # Row 1: view menu
    frame $fw1
    tixOptionMenu $fw1.fwMenu \
	-label "View:" \
	-variable gaView(current,menuIndex) \
	-command { ViewPropertiesMenuCallback }
    set gaWidget(viewProperties,menu) $fw1.fwMenu

    pack $fw1.fwMenu -fill x

    # Row 2: ID, col, row labels
    frame $fw2
    tkuMakeActiveLabel $fw2.ewID \
	-label "ID: " \
	-variable gaView(current,id) -width 2
    tkuMakeActiveLabel $fw2.ewCol \
	-label "Column: " \
	-variable gaView(current,col) -width 2
    tkuMakeActiveLabel $fw2.ewRow \
	-label "Row: " \
	-variable gaView(current,row) -width 2

    pack $fw2.ewID $fw2.ewCol $fw2.ewRow \
	-side left -fill x

    # Row 3: linked and locked cbs
    frame $fw3
    tkuMakeCheckboxes $fw3.cbwLinked \
	-checkboxes {
	    {-type text -label "Linked" -variable gaView(current,linked)
		-command {SetViewLinkedStatus $gaView(current,id) $gaView(current,linked)} }
	}

    tkuMakeCheckboxes $fw3.cbwLocked \
	-checkboxes {
	    {-type text -label "Locked on Cursor"
		-variable gaView(current,lockedCursor)
		-command {SetViewLockOnCursor $gaView(current,id) $gaView(current,lockedCursor); SetPreferencesValue LockOnCursor $gaView(current,lockedCursor); set gaPrefs(LockOnCursor) [GetPreferencesValue LockOnCursor]} }
	}

    pack $fw3.cbwLinked $fw3.cbwLocked \
	-side left -fill x

    # Row 4: The table for draw layers.
    frame $fw4 -relief raised -border 2
    tkuMakeNormalLabel $fw4.lwLevel -label "Lvl"
    tkuMakeNormalLabel $fw4.lwVisible -label "Vis"
    tkuMakeNormalLabel $fw4.lwLocked -label "Lckd"
    tkuMakeNormalLabel $fw4.lwLayer -label "Layer"

    for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {

	tkuMakeNormalLabel $fw4.lw$nLevel \
	    -label "$nLevel"

	checkbutton $fw4.cbwVisible$nLevel \
	    -variable gaView(current,visible$nLevel) \
	    -command "ViewPropertiesLevelVisibleCallback $nLevel"

	checkbutton $fw4.cbwLocked$nLevel \
	    -variable gaView(current,lockedShuffle$nLevel)
	tixOptionMenu $fw4.mwDraw$nLevel \
	    -label "" \
	    -variable gaView(current,draw$nLevel) \
	    -command "ViewPropertiesDrawLevelMenuCallback $nLevel"
	set gaWidget(viewProperties,drawLevelMenu$nLevel) \
	    $fw4.mwDraw$nLevel
    }

    grid $fw4.lwLevel   -column 0 -row 0
    grid $fw4.lwVisible -column 1 -row 0
    grid $fw4.lwLocked  -column 2 -row 0
    grid $fw4.lwLayer   -column 3 -row 0

    for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {
	grid $fw4.lw$nLevel \
	    -column 0 -row [expr $nLevel + 1] -sticky w
	grid $fw4.cbwVisible$nLevel \
	    -column 1 -row [expr $nLevel + 1] -sticky w
	grid $fw4.cbwLocked$nLevel  \
	    -column 2 -row [expr $nLevel + 1] -sticky w
	grid $fw4.mwDraw$nLevel \
	    -column 3 -row [expr $nLevel + 1] -sticky ew
    }

    grid columnconfigure $fw4 0 -weight 0
    grid columnconfigure $fw4 1 -weight 0
    grid columnconfigure $fw4 2 -weight 0
    grid columnconfigure $fw4 3 -weight 1

    # Row 5: The transform menu.
    frame $fw5
    tixOptionMenu $fw5.mwTransform \
	-label "Transform:" \
	-variable gaView(current,transformID) \
	-command "ViewPropertiesTransformMenuCallback"
    set gaWidget(viewProperties,transformMenu) \
	$fw5.mwTransform

    pack $fw5.mwTransform -fill x

    # Row 6: The copy button.    
    frame $fw6
    button $fw6.bwCopyLayers -text "Copy Layers to Other Views" \
	-command { CopyViewLayersToAllViewsInFrame [GetMainFrameID] $gaView(current,id) }

    pack $fw6.bwCopyLayers -fill x

    # Row 7: The in plane inc field.
    frame $fw7
    tkuMakeEntry $fw7.ewInPlaneInc \
	-label "Through plane key increment" \
	-font [tkuNormalFont] \
	-variable gaView(current,throughPlaneInc) \
	-command {SetViewThroughPlaneIncrement $gaView(current,id) $gaView(current,inPlane) $gaView(current,throughPlaneInc) } \
	-notify 1
    set gaWidget(viewProperties,throughPlaneInc) $fw7.ewInPlaneInc
    
    pack $fw7.ewInPlaneInc -fill x

    grid $fwProps.fw1 -column 0 -row 0 -sticky we
    grid $fwProps.fw2 -column 0 -row 1 -sticky we
    grid $fwProps.fw3 -column 0 -row 2 -sticky we
    grid $fwProps.fw4 -column 0 -row 3 -sticky nswe
    grid $fwProps.fw5 -column 0 -row 4 -sticky we
    grid $fwProps.fw6 -column 0 -row 5 -sticky we
    grid $fwProps.fw7 -column 0 -row 6 -sticky we

    grid $fwProps -column 0 -row 0 -sticky news

    grid columnconfigure $fwTop 0 -weight 1
    grid rowconfigure $fwTop 0 -weight 1

    return $fwTop
}

proc MakeTransformsPanel { ifwTop } {
    dputs "MakeTransformsPanel  $ifwTop  "

    global gaWidget
    global gaTransform

    set fwTop          $ifwTop.fwTransforms
    set fwProps        $fwTop.fwProps
    set fwCommands     $fwTop.fwCommands
 
    frame $fwTop

    frame $fwProps -relief ridge -border 2

    tixOptionMenu $fwProps.fwMenu \
	-label "Transform:" \
	-variable gaTransform(current,menuIndex) \
	-command { TransformPropertiesMenuCallback }
    set gaWidget(transformProperties,menu) $fwProps.fwMenu

    grid $fwProps.fwMenu -column 0 -row 0 -columnspan 4 -sticky new

    tkuMakeEntry $fwProps.ewLabel \
	-variable gaTransform(current,label) \
	-notify 1 \
	-command {SetTransformLabel $gaTransform(current,id) $gaTransform(current,label); UpdateTransformList} 
    set gaWidget(transformProperties,labelEntry) $fwProps.ewLabel
    
    grid $fwProps.ewLabel -column 0 -row 1 -columnspan 4 -sticky ew

    for { set nRow 0 } { $nRow < 4 } { incr nRow } {
	for { set nCol 0 } { $nCol < 4 } { incr nCol } {

	    tkuMakeEntry $fwProps.ewValue$nCol-$nRow \
		-width 6 \
		-variable gaTransform(current,value$nCol-$nRow) \
		-command { UpdateCurrentTransformValueList } \
		-notify 1
	    set gaWidget(transformProperties,value$nCol-$nRow) \
		$fwProps.ewValue$nCol-$nRow
	    
	    grid $fwProps.ewValue$nCol-$nRow \
		-column $nCol -row [expr $nRow + 2] -sticky ew
	}
    }

    button $fwProps.bwSetTransform -text "Set Values" \
	-command { SetTransformValues $gaTransform(current,id) $gaTransform(current,valueList); ClearSetTransformValuesButton }
    set gaWidget(transformProperties,setValuesButton) $fwProps.bwSetTransform

    grid $fwProps.bwSetTransform -column 0 -row 6 -columnspan 4 -sticky ew

    button $fwProps.bwInvert -text "Invert" \
	-command { InvertTransform $gaTransform(current,id); UpdateTransformList }

    grid $fwProps.bwInvert -column 0 -row 7 -columnspan 4 -sticky ew


    tkuMakeCheckboxes $fwProps.cbRegister \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Treat as registration" 
		-variable gaTransform(current,isRegistration)
		-command { SetTransformRegistration; UpdateTransformList }}
	}

    grid $fwProps.cbRegister -column 0 -row 8 -columnspan 4 -sticky ew

    tixOptionMenu $fwProps.owSource \
	-label "Source (fixed target):" \
	-variable gaTransform(current,regSource) \
	-command { TransformSourceRegistrationMenuCallback }
    set gaWidget(transformProperties,regSourceMenu) $fwProps.owSource

    grid $fwProps.owSource -column 0 -row 9 -columnspan 4 -sticky ew

    tixOptionMenu $fwProps.owDest \
	-label "Dest (movable):" \
	-variable gaTransform(current,regDest) \
	-command { TransformDestRegistrationMenuCallback }
    set gaWidget(transformProperties,regDestMenu) $fwProps.owDest

    grid $fwProps.owDest -column 0 -row 10 -columnspan 4 -sticky ew

    frame $fwCommands
    button $fwCommands.bwMakeTransform -text "Make New Transform" \
	-command { set transformID [MakeNewTransform]; SetTransformLabel $transformID "New Transform"; UpdateTransformList; SelectTransformInTransformProperties $transformID }

    pack $fwCommands.bwMakeTransform -expand yes -side top -fill x

    grid $fwProps    -column 0 -row 0 -sticky news
    grid $fwCommands -column 0 -row 1 -sticky news

    grid columnconfigure $fwTop 0 -weight 1
    grid rowconfigure $fwTop 0 -weight 1

    return $fwTop
}

proc MakeLUTsPanel { ifwTop } {
    dputs "MakeLUTsPanel  $ifwTop  "

    global gaWidget
    global gaLUT
    global glShortcutDirs

    set fwTop      $ifwTop.fwLUTs
    set fwProps    $fwTop.fwProps
    set fwCommands $fwTop.fwCommands
 
    frame $fwTop

    frame $fwProps -relief ridge -border 2

    tixOptionMenu $fwProps.fwMenu \
	-label "LUT:" \
	-variable gaLUT(current,menuIndex) \
	-command { LUTPropertiesMenuCallback }
    set gaWidget(lutProperties,menu) $fwProps.fwMenu

    tkuMakeEntry $fwProps.ewLabel \
	-variable gaLUT(current,label) \
	-notify 1 \
	-command {SetColorLUTLabel $gaLUT(current,id) $gaLUT(current,label); UpdateLUTList} 
    set gaWidget(lutProperties,labelEntry) $fwProps.ewLabel

    tkuMakeFileSelector $fwProps.fwLUT \
	-variable gaLUT(current,fileName) \
	-text "File name:" \
	-shortcutdirs [list $glShortcutDirs] \
	-command {SetColorLUTFileName $gaLUT(current,id) $gaLUT(current,fileName); UpdateLUTList; RedrawFrame [GetMainFrameID]}
    
    grid $fwProps.fwMenu  -column 0 -row 0 -sticky ew
    grid $fwProps.ewLabel -column 0 -row 1 -sticky ew
    grid $fwProps.fwLUT   -column 0 -row 2 -sticky ew

    frame $fwCommands
    button $fwCommands.bwMakeLUT -text "Make New LUT" \
	-command { set lutID [MakeNewColorLUT]; SetColorLUTLabel $lutID "New LUT"; UpdateLUTList; SelectLUTInLUTProperties $lutID }

    pack $fwCommands.bwMakeLUT -expand yes -fill x

    grid $fwProps    -column 0 -row 0 -sticky news
    grid $fwCommands -column 0 -row 1 -sticky news

    grid columnconfigure $fwTop 0 -weight 1
    grid rowconfigure $fwTop 0 -weight 1

    return $fwTop
}


# DATA COLLECTION PROPERTIES FUNCTIONS =====================================

proc CollectionPropertiesMenuCallback { iColID } {
    dputs "CollectionPropertiesMenuCallback  $iColID  "

    SelectCollectionInCollectionProperties $iColID
}

proc SelectCollectionInCollectionProperties { iColID } {
    dputs "SelectCollectionInCollectionProperties  $iColID  "

    global gaCollection

    set gaCollection(current,id) $iColID
    UpdateCurrentCollectionInCollectionProperites
}

proc UpdateCurrentCollectionInCollectionProperites {} {

    global gaWidget
    global gaCollection

    # Unpack the type-specific panels.
    grid forget $gaWidget(collectionProperties,volume)
    grid forget $gaWidget(collectionProperties,surface)

    # Get the general collection properties from the collection and
    # load them into the 'current' slots.
    set colID $gaCollection(current,id)
    set gaCollection(current,type) [GetCollectionType $colID]
    set gaCollection(current,label) [GetCollectionLabel $colID]
    set gaCollection(current,transformID) [GetDataTransform $colID]
    tkuRefreshEntryNotify $gaWidget(collectionProperties,labelEntry)

    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to collection ID. Then
    # reenable the callback.
    $gaWidget(collectionProperties,menu) config -disablecallback 1
    $gaWidget(collectionProperties,menu) config -value $colID
    $gaWidget(collectionProperties,menu) config -disablecallback 0
    
    # Select the right transform in the transform menu
    $gaWidget(collectionProperties,transformMenu) config -disablecallback 1
    $gaWidget(collectionProperties,transformMenu) config \
	-value $gaCollection(current,transformID)
    $gaWidget(collectionProperties,transformMenu) config -disablecallback 0    

    # Do the type specific stuff.
    switch $gaCollection(current,type) {
	Volume { 
	    # Pack the type panel.
	    grid $gaWidget(collectionProperties,volume) \
		-column 0 -row 2 -sticky news

	    # Get the type specific properties.
	    set gaCollection(current,fileName) \
		[GetVolumeCollectionFileName $colID]
	    set gaCollection(current,useDataToIndexTransform) \
		[GetUseVolumeDataToIndexTransform $colID]
	    set gaCollection(current,autosave) \
		[GetVolumeAutosaveOn $colID]

	    # Set the save menu items.
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuLoadPatchIndex) \
		-state disabled
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuSaveIndex) \
		-state normal \
		-label "Save $gaCollection(current,label)..."
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuSaveAsIndex) \
		-state normal \
		-label "Save $gaCollection(current,label) As..."
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuSaveCopyAsIndex) \
		-state normal \
		-label "Save Copy of $gaCollection(current,label) As..."
	}
	Surface {
	    # Pack the type panel.
	    grid $gaWidget(collectionProperties,surface) \
		-column 0 -row 2 -sticky news

	    # Get the type specific properties.
	    set gaCollection(current,fileName)\
		[GetSurfaceCollectionFileName $colID]
	    set gaCollection(current,surfaceTransformFromVolume) \
		[IsSurfaceUsingDataToSurfaceTransformFromVolume $colID]
	    set gaCollection(current,surfaceTransformVolume) \
		[GetSurfaceDataToSurfaceTransformVolume $colID]

	    # Select the right in the surface transform menu
	    $gaWidget(collectionProperties,surfaceTransformMenu) config \
		-disablecallback 1
	    $gaWidget(collectionProperties,surfaceTransformMenu) config \
		-value $gaCollection(current,surfaceTransformVolume)
	    $gaWidget(collectionProperties,surfaceTransformMenu) config \
		-disablecallback 0    

	    # Set the save menu items.
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuLoadPatchIndex) \
		-state normal
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuSaveIndex) \
		-state disabled \
		-label "Cannot save surfaces"
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuSaveAsIndex) \
		-state disabled \
		-label "Cannot save surfaces"
	    $gaWidget(Menu,fileMenu) entryconfigure \
		$gaWidget(Menu,fileMenuSaveCopyAsIndex) \
		-state disabled \
		-label "Cannot save surfaces"
	}
    }

    # Rebuild the ROI list.
    UpdateROIList
}

# This builds the data collection ID list and populates the menu that
# selects the current collection in the collection props panel.  It
# should be called whenever a collection is created or deleted.
proc UpdateCollectionList {} {
    dputs "UpdateCollectionList  "

    global gaWidget
    global gaCollection

    # Get the layer ID list and build the menu.
    set gaCollection(idList) [GetDataCollectionIDList]
    FillMenuFromList $gaWidget(collectionProperties,menu) \
	$gaCollection(idList) "GetCollectionLabel %s" {} false

    # Reselect the current collection.
    if { [info exists gaCollection(current,id)] && 
	 $gaCollection(current,id) >= 0 } {
	SelectCollectionInCollectionProperties $gaCollection(current,id)
    }

    # Build source and dest menus in transforms.
    FillMenuFromList $gaWidget(transformProperties,regSourceMenu) \
	$gaCollection(idList) "GetCollectionLabel %s" {} false
    FillMenuFromList $gaWidget(transformProperties,regDestMenu) \
	$gaCollection(idList) "GetCollectionLabel %s" {} false

    FillMenuFromList $gaWidget(collectionProperties,surfaceTransformMenu) \
	$gaCollection(idList) "GetCollectionLabel %s" {} false

    FillMenuFromList $gaWidget(toolProperties,floodSourceCollectionMenu) \
	$gaCollection(idList) "GetCollectionLabel %s" {} true

    UpdateROIList
}

proc SurfaceTransformVolumeMenuCallback { iCollectionID } {
    global gaCollection

    set gaCollection(current,surfaceTransformVolume) $iCollectionID
    SetSurfaceTransformVolume
    UpdateCurrentCollectionInCollectionProperites
}

proc SetSurfaceTransformVolume {} {
    
    global gaCollection

    if { $gaCollection(current,surfaceTransformFromVolume) } {

	SetSurfaceDataToSurfaceTransformFromVolume $gaCollection(current,id) \
	    $gaCollection(current,surfaceTransformVolume)

    } else {

	SetSurfaceDataToSurfaceTransformToDefault $gaCollection(current,id)
    }
}


# ROI PROPERTIES FUNCTIONS ===============================================

proc ROIPropertiesMenuCallback { iROIID } {
    dputs "ROIPropertiesMenuCallback  $iROIID  "

    SelectROIInROIProperties $iROIID
}

proc SelectROIInROIProperties { iROIID } {
    dputs "SelectROIInROIProperties  $iROIID  "

    global gaWidget
    global gaCollection
    global gaROI

    SelectCollectionROI $gaCollection(current,id) $iROIID

    # Get the general ROI properties from the ROI and load them into
    # the 'current' slots.
    set gaROI(current,id) $iROIID
    set gaROI(current,label) [GetROILabel $iROIID]
    tkuRefreshEntryNotify $gaWidget(roiProperties,labelEntry)
    set gaROI(current,type) [GetROIType $iROIID]
    set gaROI(current,lutID) [GetROILUTID $iROIID]
    set gaROI(current,structure) [GetROIStructure $iROIID]
    set lColor [GetROIColor $iROIID]
    set gaROI(current,redColor) [lindex $lColor 0]
    set gaROI(current,greenColor) [lindex $lColor 1]
    set gaROI(current,blueColor) [lindex $lColor 2]
    tkuUpdateColorPickerValues $gaWidget(roiProperties,freeColor)

    # Make sure that this is the item selected in the menu. Disable the
    # callback and set the value of the menu to collection ID. Then
    # reenable the callback.
    $gaWidget(roiProperties,menu) config -disablecallback 1
    $gaWidget(roiProperties,menu) config -value $iROIID
    $gaWidget(roiProperties,menu) config -disablecallback 0

    # Show the right LUT in the listbox.
    SelectLUTInROIProperties $gaROI(current,lutID)

    SelectStructureInROIProperties $gaROI(current,structure)
}

proc ClearROIInROIProperties {} {
    dputs "ClearROIInROIProperties  "

    global gaWidget
    global gaROI

    # Clear the stuff in the current slots.
    set gaROI(current,id) -1
    set gaROI(current,label) ""
    tkuRefreshEntryNotify $gaWidget(roiProperties,labelEntry)
    
    # Clear the listbox.
    $gaWidget(roiProperties,structureListBox) subwidget listbox \
	delete 0 end
}

proc ROIPropertiesLUTMenuCallback { iLUTID } {
    dputs "ROIPropertiesLUTMenuCallback  $iLUTID  "

    SelectLUTInROIProperties $iLUTID
}


proc CollectionPropertiesTransformMenuCallback { iTransformID } {
    dputs "CollectionPropertiesTransformMenuCallback  $iTransformID  "

    global gaCollection
    global gaTransform
    
    # Set the transform in this collection and redraw.
    SetDataTransform $gaCollection(current,id) $iTransformID
    RedrawFrame [GetMainFrameID]
}

proc SelectLUTInROIProperties { iLUTID } {
    dputs "SelectLUTInROIProperties  $iLUTID  "

    global gaROI
    global gaWidget
    global gaCollection

    # Set the ROI data if we can.
    catch {
	set gaROI(current,lutID) $iLUTID
	SetROILUTID $gaROI(current,id) $gaROI(current,lutID)
    }

    # Clear the listbox.
    $gaWidget(roiProperties,structureListBox) subwidget listbox \
	delete 0 end

    # Put the entries in the list box.
    set cEntries [GetColorLUTNumberOfEntries $gaROI(current,lutID)]
    for { set nEntry 0 } { $nEntry < $cEntries } { incr nEntry } {
	catch {
	    set sLabel "$nEntry: [GetColorLUTEntryLabel $gaROI(current,lutID) $nEntry]"
	    $gaWidget(roiProperties,structureListBox) subwidget listbox \
		insert end $sLabel
	}
    }

    # Make sure the right menu item is selected.
    $gaWidget(roiProperties,lutMenu) config -disablecallback 1
    $gaWidget(roiProperties,lutMenu) config -value $iLUTID
    $gaWidget(roiProperties,lutMenu) config -disablecallback 0

    SelectStructureInROIProperties $gaROI(current,structure)
}

proc ROIPropertiesStructureListBoxCallback {} {
    dputs "ROIPropertiesStructureListBoxCallback  "

    global gaWidget

    set nStructure [$gaWidget(roiProperties,structureListBox) \
			subwidget listbox curselection]

    SelectStructureInROIProperties $nStructure
}


proc SelectStructureInROIProperties { inStructure } {
    dputs "SelectStructureInROIProperties  $inStructure  "

    global gaROI
    global gaWidget
    
    # Set value in ROI.
    catch {
	set gaROI(current,structure) $inStructure
	SetROIStructure $gaROI(current,id) $gaROI(current,structure)
	RedrawFrame [GetMainFrameID]

	# Set the label.
	set gaROI(current,structureLabel) "$inStructure: [GetColorLUTEntryLabel $gaROI(current,lutID) $inStructure]"
    }
    
    # Make sure the structure is highlighted and visible in the listbox.
    catch {
	$gaWidget(roiProperties,structureListBox) subwidget listbox \
	    selection clear 0 end
	$gaWidget(roiProperties,structureListBox) subwidget listbox \
	    selection set $gaROI(current,structure)
	$gaWidget(roiProperties,structureListBox) subwidget listbox \
	    see $gaROI(current,structure)
    }

}

# This builds the roi ID list based on the current data collection and
# populates the menu that selects the current roi in the
# collection/roi props panel.  It should be called whenever a
# collection or roi is created or deleted or when a new collection is
# selected.
proc UpdateROIList {} {
    dputs "UpdateROIList  "

    global gaWidget
    global gaCollection
    global gaROI

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= 0} {

	# Get the roi ID list and build the menu.
	set gaROI(idList) [GetROIIDListForCollection $gaCollection(current,id)]
	FillMenuFromList $gaWidget(roiProperties,menu) \
	    $gaROI(idList) "GetROILabel %s" {} false

	# Reselect the current ROI. If it doesn't exist in this
	# collection, get a new roi ID from the list we got from the
	# collection. If there aren't any, clear the properties.
	if { [info exists gaROI(current,id)] } {
	    if { [lsearch $gaROI(idList) $gaROI(current,id)] == -1 } {
		if { [llength $gaROI(idList)] > 0 } {
		    set gaROI(current,id) [lindex $gaROI(idList) 0]
		} else {
		    ClearROIInROIProperties
		    return
		}
	    }
	    SelectROIInROIProperties $gaROI(current,id)
	}
    }
}

# LAYER PROPERTIES FUNCTIONS ===========================================

proc LayerPropertiesMenuCallback { iLayerID } {
    dputs "LayerPropertiesMenuCallback  $iLayerID  "

    SelectLayerInLayerProperties $iLayerID
}

proc LayerPropertiesLUTMenuCallback { iLUTID } {
    dputs "LayerPropertiesLUTMenuCallback  $iLUTID  "

    global gaLayer
    
    # Set the LUT in this layer and redraw.
    Set2DMRILayerColorLUT $gaLayer(current,id) $iLUTID
    RedrawFrame [GetMainFrameID]
}

proc SelectLayerInLayerProperties { iLayerID } {
    dputs "SelectLayerInLayerProperties  $iLayerID  "

    global gaWidget
    global gaLayer

    # Unpack the type-specific panels.
    grid forget $gaWidget(layerProperties,2DMRI)
    grid forget $gaWidget(layerProperties,2DMRIS)

    # Get the general layer properties from the specific layer and
    # load them into the 'current' slots.
    set gaLayer(current,id) $iLayerID
    set gaLayer(current,type) [GetLayerType $iLayerID]
    set gaLayer(current,label) [GetLayerLabel $iLayerID]
    set gaLayer(current,opacity) [GetLayerOpacity $iLayerID]
    tkuRefreshEntryNotify $gaWidget(layerProperties,labelEntry)

    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to the layer ID. Then
    # reenable the callback.
    $gaWidget(layerProperties,menu) config -disablecallback 1
    $gaWidget(layerProperties,menu) config -value $iLayerID
    $gaWidget(layerProperties,menu) config -disablecallback 0
    
    # Do the type specific stuff.
    switch $gaLayer(current,type) {
	2DMRI { 
	    # Pack the type panel.
	    grid $gaWidget(layerProperties,2DMRI) -column 0 -row 2 -sticky news

	    # Configure the length of the value sliders.
	    set gaLayer(current,minValue) [Get2DMRILayerMinValue $iLayerID]
	    set gaLayer(current,maxValue) [Get2DMRILayerMaxValue $iLayerID]
	    tkuUpdateSlidersRange $gaWidget(layerProperties,minMaxSliders) \
		$gaLayer(current,minValue) $gaLayer(current,maxValue)

	    # Get the type specific properties.
	    set gaLayer(current,colorMapMethod) \
		[Get2DMRILayerColorMapMethod $iLayerID]
	    set gaLayer(current,clearZero) \
		[Get2DMRILayerDrawZeroClear $iLayerID]
	    set gaLayer(current,sampleMethod) \
		[Get2DMRILayerSampleMethod $iLayerID]
	    set gaLayer(current,brightness) [Get2DMRILayerBrightness $iLayerID]
	    set gaLayer(current,contrast) [Get2DMRILayerContrast $iLayerID]
	    set gaLayer(current,lutID) [Get2DMRILayerColorLUT $iLayerID]
	    set gaLayer(current,minVisibleValue) \
		[Get2DMRILayerMinVisibleValue $iLayerID]
	    set gaLayer(current,maxVisibleValue) \
		[Get2DMRILayerMaxVisibleValue $iLayerID]
	    set gaLayer(current,editableROI) \
		[Get2DMRILayerEditableROI $iLayerID]
	    set gaLayer(current,roiOpacity) \
		[Get2DMRILayerROIOpacity $iLayerID]

	    # Set the LUT menu.
	    $gaWidget(layerProperties,lutMenu) config -disablecallback 1
	    $gaWidget(layerProperties,lutMenu) config \
		-value $gaLayer(current,lutID)
	    $gaWidget(layerProperties,lutMenu) config -disablecallback 0    
	}
	2DMRIS {
	    # Pack the type panel.
	    grid $gaWidget(layerProperties,2DMRIS) \
		-column 0 -row 2 -sticky news

	    # Get the type specific properties.
	    set lColor [Get2DMRISLayerLineColor $iLayerID]
	    set gaLayer(current,redLineColor) [lindex $lColor 0]
	    set gaLayer(current,greenLineColor) [lindex $lColor 1]
	    set gaLayer(current,blueLineColor) [lindex $lColor 2]

	    set lColor [Get2DMRISLayerVertexColor $iLayerID]
	    set gaLayer(current,redVertexColor) [lindex $lColor 0]
	    set gaLayer(current,greenVertexColor) [lindex $lColor 1]
	    set gaLayer(current,blueVertexColor) [lindex $lColor 2]

	    # Configure color selector.
	    tkuUpdateColorPickerValues \
		$gaWidget(layerProperties,lineColorPickers)
	    tkuUpdateColorPickerValues \
		$gaWidget(layerProperties,vertexColorPickers)
	}
    }
}

proc 2DMRILayerMinMaxValueChanged { iLayerID } {
    global gaLayer
    global gaWidget

    if { $gaLayer(current,id) == $iLayerID } {
	
	set gaLayer(current,minValue) [Get2DMRILayerMinValue $iLayerID]
	set gaLayer(current,maxValue) [Get2DMRILayerMaxValue $iLayerID]
	tkuUpdateSlidersRange $gaWidget(layerProperties,minMaxSliders) \
	    $gaLayer(current,minValue) $gaLayer(current,maxValue)

	set gaLayer(current,minVisibleValue) \
	    [Get2DMRILayerMinVisibleValue $iLayerID]
	set gaLayer(current,maxVisibleValue) \
	    [Get2DMRILayerMaxVisibleValue $iLayerID]
    }
}

# This builds the layer ID list and populates the menu that selects
# the current layer in the layer props panel, and the menus in the
# view props panel. It should be called whenever a layer is created or
# deleted, or when a lyer is added to or removed from a view.
proc UpdateLayerList {} {
    dputs "UpdateLayerList  "

    global gaLayer
    global gaWidget
    global gaView
    global gaTool

    # We have two jobs here. First we need to populate the menu that
    # selects the current layer in the layer props panel. Then we need
    # to populate all the level-layer menus in the view props
    # panel. First do the layer props.

    # Get the layer ID list and build the menu.
    set gaLayer(idList) [GetLayerIDList]
    FillMenuFromList $gaWidget(layerProperties,menu) $gaLayer(idList) \
	"GetLayerLabel %s" {} false

    # Reselect the current layer.
    if { [info exists gaLayer(current,id)] && 
	 $gaLayer(current,id) >= 0 } {
	SelectLayerInLayerProperties $gaLayer(current,id)
    }


    # Populate the menus in the view props draw level menus.
    for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {

	FillMenuFromList $gaWidget(viewProperties,drawLevelMenu$nLevel) \
	    $gaLayer(idList) "GetLayerLabel %s" {} true
    }

    # Populate layer target and source menus in tool properties.
    FillMenuFromList $gaWidget(toolProperties,targetLayerMenu) \
	$gaLayer(idList) "GetLayerLabel %s" {} true

    # Make sure the right layers are selected in the view draw level
    # menus.
    UpdateCurrentViewProperties
}

# VIEW PROPERTIES FUNCTIONS =============================================

proc ViewPropertiesMenuCallback { iViewID } {
    dputs "ViewPropertiesMenuCallback  $iViewID  "

    SelectViewInViewProperties $iViewID
}

proc ViewPropertiesDrawLevelMenuCallback { iLevel iLayerID } {
    dputs "ViewPropertiesDrawLevelMenuCallback  $iLevel $iLayerID  "

    global gaView
    global gaLayer
    
    # Set the layer in this view and redraw.
    SetLayerInViewAtLevel $gaView(current,id) $iLayerID $iLevel
    RedrawFrame [GetMainFrameID]

    # Get the new inplane inc value if necessary.
    set gaView(current,throughPlaneInc) \
	[GetViewThroughPlaneIncrement $gaView(current,id) $gaView(current,inPlane)]
}

proc ViewPropertiesTransformMenuCallback { iTransformID } {
    dputs "ViewPropertiesTransformMenuCallback  $iTransformID  "

    global gaView
    global gaTransform
    
    # Set the transform in this view and redraw.
    SetViewTransform $gaView(current,id) $iTransformID
    RedrawFrame [GetMainFrameID]
}

proc SelectViewInViewProperties { iViewID } {
    dputs "SelectViewInViewProperties  $iViewID  "

    global gaWidget
    global gaView

    if { [lsearch $gaView(idList) $iViewID] == -1 } {
	return
    }
    
    SetSelectedViewID [GetMainFrameID] $iViewID

    # Get the general view properties from the specific view and
    # load them into the 'current' slots.
    set gaView(current,id) $iViewID
    set gaView(current,col) [GetColumnOfViewInFrame [GetMainFrameID] $iViewID]
    set gaView(current,row) [GetRowOfViewInFrame [GetMainFrameID] $iViewID]
    set gaView(current,linked) [GetViewLinkedStatus $iViewID]
    set gaView(current,lockedCursor) [GetViewLockOnCursor $iViewID]
    set gaView(current,transformID) [GetViewTransform $iViewID]
    set gaView(current,inPlane) [GetViewInPlane $iViewID]
    set gaView(current,throughPlaneInc) \
      [GetViewThroughPlaneIncrement $iViewID $gaView(current,inPlane)]
    tkuRefreshEntryNotify $gaWidget(viewProperties,throughPlaneInc)

    # This is kind of hacky. We have a preference for the Lock on
    # Cursor setting. What we want to do is see if we've gotten the
    # setting from the prefs yet for this view. If not, set this
    # view's setting to the prefs. If the checkbox is manually
    # clicked, we'll change the pref to the new value.
    if { ![info exists gaView(lockOverride,$iViewID)] } {
	set gaView(current,lockedCursor) [GetPreferencesValue LockOnCursor]
	SetViewLockOnCursor $iViewID true
	set gaView(lockOverride,$iViewID) 1
    }

    # This is the same for every view but get it here anyway.
    set gaView(numMarkers) [GetNumberOfViewMarkers]
    tkuRefreshEntryNotify $gaWidget(toolProperties,numMarkersEntry)

    for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {
	set gaView(current,visible$nLevel) \
	    [GetLevelVisibilityInView $iViewID $nLevel]

	$gaWidget(viewProperties,drawLevelMenu$nLevel) \
	    config -disablecallback 1
	set gaView(current,draw$nLevel) \
	    [GetLayerInViewAtLevel $iViewID $nLevel]
	$gaWidget(viewProperties,drawLevelMenu$nLevel) \
	    config -disablecallback 0
    }
    
    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to the view ID. Then
    # reenable the callback.
    $gaWidget(viewProperties,menu) config -disablecallback 1
    $gaWidget(viewProperties,menu) config -value $iViewID
    $gaWidget(viewProperties,menu) config -disablecallback 0

    # Select the right transform in the transform menu
    $gaWidget(viewProperties,transformMenu) config -disablecallback 1
    $gaWidget(viewProperties,transformMenu) config \
	-value $gaView(current,transformID)
    $gaWidget(viewProperties,transformMenu) config -disablecallback 0    

    UpdateCurrentViewProperties
}

# This gets the layers at each level of the currently selected view
# and makes sure the draw level menus are set properly. Call it
# whenever a layer has been set in the current view.
proc UpdateCurrentViewProperties {} {
    dputs "UpdateCurrentViewProperties  "

    global gaWidget
    global gaView
    global gaLayer

    set sHighestLabel "None"
    for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {

	# Get the current value of this layer.
	set layerID [GetLayerInViewAtLevel $gaView(current,id) $nLevel]

	# Disable callback.
	$gaWidget(viewProperties,drawLevelMenu$nLevel) \
	    config -disablecallback 1

	# Set the layer id in the draw level.
	$gaWidget(viewProperties,drawLevelMenu$nLevel) config -value $layerID

	# Renable the callback.
	$gaWidget(viewProperties,drawLevelMenu$nLevel) \
	    config -disablecallback 0

	# Get the layer label.
	if { $layerID > -1 } {
	    set sHighestLabel [GetLayerLabel $layerID]
	}
    }

    # Put the title of the top layer in the window title bar.
    wm title $gaWidget(window) "scuba: $sHighestLabel"
}

proc ViewPropertiesLevelVisibleCallback { inLevel } {

    global gaView

    SetLevelVisibilityInView $gaView(current,id) $inLevel $gaView(current,visible$inLevel)
    UpdateCursorLabelArea
    RedrawFrame [GetMainFrameID]
}

# This builds the view ID list from the current view configuration and
# populates the menu that selects the view in the view props panel. It
# should be called every time the view configuration changes.
proc UpdateViewList {} {
    dputs "UpdateViewList  "

    global gaView
    global gaWidget

    set gaView(idList) {}
    set gaView(labelList) {}
    
    # Build the ID list.
    set err [catch { set cRows [GetNumberOfRowsInFrame [GetMainFrameID]] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return }
    for { set nRow 0 } { $nRow < $cRows } { incr nRow } {
	
	set err [catch { 
	    set cCols [GetNumberOfColsAtRowInFrame [GetMainFrameID] $nRow]
	} sResult]
	if { 0 != $err } { tkuErrorDlog $sResult; return }
	
	for { set nCol 0 } { $nCol < $cCols } { incr nCol } {

	    set err [catch { 
		set viewID [GetViewIDFromFrameColRow [GetMainFrameID] $nCol $nRow] 
	    } sResult]
	    if { 0 != $err } { tkuErrorDlog $sResult; return }

	    lappend gaView(idList) $viewID

	    lappend gaView(labelList) "[GetColumnOfViewInFrame [GetMainFrameID] $viewID], [GetRowOfViewInFrame [GetMainFrameID] $viewID]"
	}
    }

    FillMenuFromList $gaWidget(viewProperties,menu) $gaView(idList) \
	"" $gaView(labelList) false
}

# TOOL PROPERTIES FUNCTIONS =============================================

proc ToolPropertiesMenuCallback { iTool } {
    SelectToolInToolProperties $iTool
}

proc SelectToolInToolProperties { iTool } {
    dputs "SelectToolInToolProperties  $iTool"

    global gaWidget
    global gaTool
    global gaFrame

    # Unpack the type-specific panels.
    grid forget $gaWidget(toolProperties,brush)
    grid forget $gaWidget(toolProperties,fill)
    grid forget $gaWidget(toolProperties,marker)
    grid forget $gaWidget(toolProperties,edgePath)
    grid forget $gaWidget(toolProperties,voxelEditing)

    # Get the general layer properties from the specific layer and
    # load them into the 'current' slots.
    set gaTool(current,id) $gaFrame([GetMainFrameID],toolID)
    set gaTool(current,type) $iTool

    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to the layer ID. Then
    # reenable the callback.
    $gaWidget(toolProperties,menu) config -disablecallback 1
    $gaWidget(toolProperties,menu) config -value $iTool
    $gaWidget(toolProperties,menu) config -disablecallback 0
    
    # Set this tool in the toolbar too.
    set gaTool($gaFrame([GetMainFrameID],toolID),mode) $gaTool(current,type)

    # Get the target layer.
    set gaTool(current,targetLayer) [GetToolTargetLayer $gaTool(current,id)]

    $gaWidget(toolProperties,targetLayerMenu) config -disablecallback 1
    $gaWidget(toolProperties,targetLayerMenu) config -value $gaTool(current,targetLayer)
    $gaWidget(toolProperties,targetLayerMenu) config -disablecallback 0

    # Do the type specific stuff. Pack the relevant tool panels.
    switch $gaTool(current,type) {
	roiEditing - voxelEditing { 
	    # ROI and voxel editing get brush and fill stuff.
	    grid $gaWidget(toolProperties,brush) -column 0 -row 2 -sticky ew

	    set gaTool(current,brushShape) \
		[GetToolBrushShape $gaTool(current,id)]
	    set gaTool(current,radius) \
		[GetToolBrushRadius $gaTool(current,id)]
	    set gaTool(current,brush3D) \
		[GetToolBrush3D $gaTool(current,id)]
	    set gaTool(current,onlyBrushZero) \
		[GetToolOnlyBrushZero $gaTool(current,id)]

	    grid $gaWidget(toolProperties,fill)  -column 0 -row 3 -sticky ew

	    set gaTool(current,floodSourceCollection) \
		[GetToolFloodSourceCollection $gaTool(current,id)]
	    set gaTool(current,stopROI) \
		[GetToolFloodStopAtROIs $gaTool(current,id)]
	    set gaTool(current,stopPaths) \
		[GetToolFloodStopAtPaths $gaTool(current,id)]
	    set gaTool(current,fuzziness) \
		[GetToolFloodFuzziness $gaTool(current,id)]
	    set gaTool(current,fuzzinessType) \
		[GetToolFloodFuzzinessType $gaTool(current,id)]
	    set gaTool(current,maxDistance) \
		[GetToolFloodMaxDistance $gaTool(current,id)]
	    set gaTool(current,flood3D) \
		[GetToolFlood3D $gaTool(current,id)]
	    set gaTool(current,onlyFloodZero) \
		[GetToolOnlyFloodZero $gaTool(current,id)]

	    if { "$gaTool(current,type)" == "voxelEditing" ||
	         "$gaTool(current,type)" == "roiEditing" } {

		grid $gaWidget(toolProperties,voxelEditing) \
		    -column 0 -row 4 -sticky news

		set gaTool(current,newVoxelValue) \
		    [GetToolNewVoxelValue $gaTool(current,id)]
		tkuRefreshEntryNotify \
		    $gaWidget(toolProperties,newVoxelValueEntry)

		set gaTool(current,eraseVoxelValue) \
		    [GetToolEraseVoxelValue $gaTool(current,id)]
		tkuRefreshEntryNotify \
		    $gaWidget(toolProperties,eraseVoxelValueEntry)
	    }
	}
	marker { 
	    grid $gaWidget(toolProperties,marker) -column 0 -row 2 -sticky ew
	}
	edgePath { 
	    grid $gaWidget(toolProperties,edgePath) -column 0 -row 2 -sticky ew

	    set gaTool(current,edgeBias) \
		[GetToolEdgePathEdgeBias $gaTool(current,id)]
	}
    }
}

proc ToolTargetLayerMenuCallback { iLayer } {
    global gaTool
    global gaWidget
    
    set gaTool(current,targetLayer) $iLayer
    SetToolTargetLayer $gaTool(current,id) $gaTool(current,targetLayer)

    # Update the radius slider.
    set inc [GetLayerPreferredBrushRadiusIncrement $iLayer]
    set min $inc
    set max [expr 20 * $inc]
    tkuUpdateSlidersRange $gaWidget(toolProperties,radiusSlider) \
	$min $max $inc
}

proc ToolFloodSourceCollectionMenuCallback { iLayer } {
    
    global gaTool

    set gaTool(current,floodSourceCollection) $iLayer
    SetToolFloodSourceCollection $gaTool(current,id) \
	$gaTool(current,floodSourceCollection)
}

proc VoxelEditingLUTMenuCallback { iLUTID } {
    dputs "VoxelEditingLUTMenuCallback  $iLUTID  "

    SelectLUTInVoxelEditingStructureListBox $iLUTID
}

proc SelectLUTInVoxelEditingStructureListBox { iLUTID } {
    dputs "SelectLUTInVoxelEditingStructureListBox  $iLUTID  "

    global gaWidget
    global gaCollection
    global gaTool

    set gaTool(current,voxelLutID) $iLUTID

    SortVoxelEditingStructureListBox

    # Make sure the right menu item is selected.
    $gaWidget(toolProperties,voxelLutMenu) config -disablecallback 1
    $gaWidget(toolProperties,voxelLutMenu) config -value $iLUTID
    $gaWidget(toolProperties,voxelLutMenu) config -disablecallback 0

    SelectStructureInVoxelEditingListBox $gaTool(current,newVoxelValue)
}

proc VoxelEditingStructureListBoxCallback {} {
    dputs "VoxelEditingLUTMenuCallback  "

    global gaTool
    global gaWidget

    set nEntry [$gaWidget(toolProperties,voxelStructureListBox) \
		    subwidget listbox curselection]
    if { $nEntry == "" } { return }
    set nStructure $gaTool(structureListOrder,entryToIndex,$nEntry)

    # Increment our user count.
    if { "$gaTool(structureListOrder,type)" == "table" } {
	if { [info exists gaTool(structureListOrder,count,$nStructure)] } {
	    incr gaTool(structureListOrder,count,$nStructure)
	} else {
	    set gaTool(structureListOrder,count,$nStructure) 0
	}
    }

    # Select the structure.
    SelectStructureInVoxelEditingListBox $nStructure
}

proc SortVoxelEditingStructureListBox {} {
    dputs "SortVoxelEditingStructureListBox"
    
    global gaWidget
    global gaTool

    # Don't do this if we haven't selected an LUT yet.
    if { ![info exists gaTool(current,voxelLutID)] } {
	return;
    }
    
    # Clear the listbox.
    $gaWidget(toolProperties,voxelStructureListBox) subwidget listbox \
	delete 0 end

    # Put the entries in the list box.
    set cStructures [GetColorLUTNumberOfEntries $gaTool(current,voxelLutID)]

    # If table order, just insert them in the order of the table.
    if { "$gaTool(structureListOrder,type)" == "table" } {
	
	set nEntry 0
	for { set nStructure 0 } { $nStructure < $cStructures } { incr nStructure } {
	    catch {
		# Get a label.
		set sLabel "$nStructure: [GetColorLUTEntryLabel $gaTool(current,voxelLutID) $nStructure]"

		# Insert the item.
		$gaWidget(toolProperties,voxelStructureListBox) subwidget \
		    listbox insert end $sLabel

		# Hook up index->structure tables.
		set gaTool(structureListOrder,indexToEntry,$nStructure) $nEntry
		set gaTool(structureListOrder,entryToIndex,$nEntry) $nStructure
		incr nEntry
	    }
	}

	# If user order, first get all the items that have counts >
	# 0. Then sort the list according to counts. Then go through
	# the sorted list and insert stuff in the listbox.
    } elseif { "$gaTool(structureListOrder,type)" == "user" } {

	set lEntries {}
	for { set nStructure 0 } { $nStructure < $cStructures } { incr nStructure } {
	    catch {
		set sLabel "$nStructure: [GetColorLUTEntryLabel $gaTool(current,voxelLutID) $nStructure]"

		# Get the count and if > 0, make an entry into our
		# unsorted list.
		set count $gaTool(structureListOrder,count,$nStructure)
		if { $count > 0 } {
		    lappend lEntries [list $sLabel $nStructure $count]
		}
	    }
	}

	# Sort the list with our sort function.
	set lSorted [lsort -command CompareLUTEntry $lEntries]

	# Now go through the sorted list and insert normally.
	set nEntry 0
	foreach entry $lSorted {

	    set sLabel [lindex $entry 0]
	    set nStructure [lindex $entry 1]

	    $gaWidget(toolProperties,voxelStructureListBox) subwidget \
		listbox insert end $sLabel
	    
	    set gaTool(structureListOrder,indexToEntry,$nStructure) $nEntry
	    set gaTool(structureListOrder,entryToIndex,$nEntry) $nStructure
	    incr nEntry
	}
    }
}


# Our list sorter, sorts by decreasing count first then by increasing
# structure index. Input is a {label structure count} triple.
proc CompareLUTEntry { a b } {
    
    set countA [lindex $a 2]
    set countB [lindex $b 2]

    set result 0
    if { $countA == $countB } {
	set structureA [lindex $a 1]
	set structureB [lindex $b 1]
	set result [expr $structureA > $structureB]
    } else {
	set result [expr $countA < $countB]
    }

    return $result
}


proc SelectStructureInVoxelEditingListBox { inStructure } {
    dputs "SelectStructureInVoxelEditingListBox  $inStructure  "

    global gaTool
    global gaWidget
    
    # Set value in tool.
    catch {
	set gaTool(current,newVoxelValue) $inStructure
	tkuRefreshEntryNotify \
	    $gaWidget(toolProperties,newVoxelValueEntry)
	SetToolNewVoxelValue $gaTool(current,id) $gaTool(current,newVoxelValue)
    }

    if { "$gaTool(structureListOrder,type)" == "user" } {
	SortVoxelEditingStructureListBox
    }

    # Make sure the structure is highlighted and visible in the listbox.
    catch {
	set nEntry $gaTool(structureListOrder,indexToEntry,$inStructure)
	$gaWidget(toolProperties,voxelStructureListBox) subwidget listbox \
	    selection clear 0 end
	$gaWidget(toolProperties,voxelStructureListBox) subwidget listbox \
	    selection set $nEntry
	$gaWidget(toolProperties,voxelStructureListBox) subwidget listbox \
	    see $nEntry
    }
}

proc ToolSettingsChanged { iToolID } {
    global gaTool
    global gaLUT
    global gaWidget

    if { $gaTool(current,id) == $iToolID } {
	
	# Re-get some of the tool data that might have changed. Right
	# now this function is only called when the newValue is
	# changed.
	set gaTool(current,newVoxelValue) \
	    [GetToolNewVoxelValue $gaTool(current,id)]
	tkuRefreshEntryNotify \
	    $gaWidget(toolProperties,newVoxelValueEntry)

	set nStructure [format "%.0f" $gaTool(current,newVoxelValue)]
	if { [catch {
	    if { [expr $nStructure <= \
		      [GetColorLUTNumberOfEntries $gaLUT(current,id)]] } {
		# Make sure the structure is highlighted and visible
		# in the listbox.
		set nEntry $gaTool(structureListOrder,indexToEntry,$nStructure)
		$gaWidget(toolProperties,voxelStructureListBox) \
		    subwidget listbox selection clear 0 end
		$gaWidget(toolProperties,voxelStructureListBox) \
		    subwidget listbox selection set $nEntry
		$gaWidget(toolProperties,voxelStructureListBox) \
		    subwidget listbox see $nEntry
	    }
	} sResult] != 0 } {
	    ::tkcon_tcl_puts "Error: $sResult"
	}
    }
}

proc ClearUserStructureList {} {
    global gaTool

    set cStructures [GetColorLUTNumberOfEntries $gaTool(current,voxelLutID)]
    for { set nStructure 0 } { $nStructure < $cStructures } { incr nStructure } {
	set gaTool(structureListOrder,count,$nStructure) 0
    }

    SortVoxelEditingStructureListBox
}

# SUBJECTS LOADER FUNCTIONS =============================================

proc SubjectsLoaderSubjectMenuCallback { inSubject } {
    dputs "SubjectsLoaderSubjectMenuCallback  $inSubject  "

    global gaSubject

    # Get the name at this index in the nameList, then select that
    # subject.
    set gaSubject(current) [lindex $gaSubject(nameList) $inSubject]
    SelectSubjectInSubjectsLoader $gaSubject(current)
}

proc SelectSubjectInSubjectsLoader { isSubject } {
    dputs "SelectSubjectInSubjectsLoader  $isSubject  "

    global gaWidget
    global gaSubject
    global env

    # Make sure we know this subject.
    set nSubject [lsearch $gaSubject(nameList) $isSubject]
    if { $nSubject == -1 } {
	return
    }

    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to the index of this
    # subject name in the subject name list. Then reenable the callback.
    $gaWidget(subjectsLoader,subjectsMenu) config -disablecallback 1
    $gaWidget(subjectsLoader,subjectsMenu) config -value $nSubject
    $gaWidget(subjectsLoader,subjectsMenu) config -disablecallback 0

    # We need to populate the data menus for this subject.  Empty them
    # first.

    set lEntries [$gaWidget(subjectsLoader,volumeMenu) entries]
    foreach entry $lEntries { 
	$gaWidget(subjectsLoader,volumeMenu) delete $entry
    }

    # For volumes, look for all the $sSubject/mri/ subdirs except
    # transforms.and tmp. Make sure they have COR-.info files in
    # them. Or, can be a .mgh or .mgz file.
    set lContents [dir -full $env(SUBJECTS_DIR)/$isSubject/mri]
    foreach sItem $lContents {
	if { ( [file isdirectory $env(SUBJECTS_DIR)/$isSubject/mri/$sItem] &&
	       [file exists $env(SUBJECTS_DIR)/$isSubject/mri/$sItem/COR-.info]) ||
	     [file extension $sItem] == ".mgh"  ||
	     [file extension $sItem] == ".mgz"} {
	    set sVolume [string trim $sItem /]
	    if { "$sVolume" != "transforms" &&
		 "$sVolume" != "tmp" } {
		$gaWidget(subjectsLoader,volumeMenu) add \
		    command "$env(SUBJECTS_DIR)/$isSubject/mri/$sItem" \
		    -label $sVolume
	    }
	}
    }
    
    set lEntries [$gaWidget(subjectsLoader,surfaceMenu) entries]
    foreach entry $lEntries { 
	$gaWidget(subjectsLoader,surfaceMenu) delete $entry
    }
    # For surfaces, look for all the $sSubject/surf/{l,r}h files.
    set lContents [dir -full $env(SUBJECTS_DIR)/$isSubject/surf]
    foreach sItem $lContents {
	if { [string range $sItem 0 1] == "lh" ||
	     [string range $sItem 0 1] == "rh" } {
	    $gaWidget(subjectsLoader,surfaceMenu) add \
		command "$env(SUBJECTS_DIR)/$isSubject/surf/$sItem" \
		-label $sItem
	}
    }
    

    set lEntries [$gaWidget(subjectsLoader,transformMenu) entries]
    foreach entry $lEntries { 
	$gaWidget(subjectsLoader,transformMenu) delete $entry
    }
    # For transforms, look for all the $sSubject/mri/transforms/*lta and *xfm.
    set lContents [dir -full $env(SUBJECTS_DIR)/$isSubject/mri/transforms]
    foreach sItem $lContents {
	if { [file extension $sItem] == ".lta" ||
	     [file extension $sItem] == ".xfm" } {
	    $gaWidget(subjectsLoader,transformMenu) add \
		command "$env(SUBJECTS_DIR)/$isSubject/mri/transforms/$sItem" \
		-label $sItem
	}
    }
    
}

proc LoadVolumeFromSubjectsLoader { isVolume } {
    dputs "LoadVolumeFromSubjectsLoader  $isVolume  "

    global gaSubject

    LoadVolume "$isVolume" 1 [GetMainFrameID]
}

proc LoadSurfaceFromSubjectsLoader { isSurface } {
    dputs "LoadSurfaceFromSubjectsLoader  $isSurface  "

    global gaSubject

    LoadSurface "$isSurface" 1 [GetMainFrameID]
}

# Builds the subject nameList by looking in SUBJECTS_DIR.
proc UpdateSubjectList {} {
    dputs "UpdateSubjectList  "

    global gaSubject
    global gaWidget
    global env

    set gaSubject(nameList) {}

    # Disable the menu.
    $gaWidget(subjectsLoader,subjectsMenu) config -disablecallback 1

    # Build the ID list. Go through and make sure each is a
    # directory. Trim slashes.
    set lContents [dir -full $env(SUBJECTS_DIR)]
    foreach sItem $lContents {
	if { [file isdirectory $env(SUBJECTS_DIR)/$sItem] } {
	    lappend gaSubject(nameList) [string trim $sItem /]
	}
    }

    # Empty the current subject menu.
    set lEntries [$gaWidget(subjectsLoader,subjectsMenu) entries]
    foreach entry $lEntries { 
	$gaWidget(subjectsLoader,subjectsMenu) delete $entry
    }
    
    # Add the entries from the subject name list to the menu.
    set nSubject 0
    foreach sSubject $gaSubject(nameList) {
	$gaWidget(subjectsLoader,subjectsMenu) add command $nSubject -label $sSubject
	incr nSubject
    }

    # Reenable the menu.
    $gaWidget(subjectsLoader,subjectsMenu) config -disablecallback 0

    # If we don't have a subject select, select the first one.
    if { ![info exists gaSubject(current,id)] } {
	SelectSubjectInSubjectsLoader [lindex $gaSubject(nameList) 0]
    }
}

# TRANSFORM PROPERTIES FUNCTIONS =========================================

proc TransformPropertiesMenuCallback { iTransformID } {
    dputs "TransformPropertiesMenuCallback  $iTransformID  "

    SelectTransformInTransformProperties $iTransformID
}

proc SelectTransformInTransformProperties { iTransformID } {
    dputs "SelectTransformInTransformProperties  $iTransformID  "

    global gaTransform

    set gaTransform(current,id) $iTransformID

    UpdateCurrentTransformInTransformProperties
}

proc  UpdateCurrentTransformInTransformProperties {} {
    global gaWidget
    global gaTransform

    # Get the tranforms properties from the transofmr layer and
    # load them into the 'current' slots.
    set transformID $gaTransform(current,id)
    set gaTransform(current,label) [GetTransformLabel $transformID]
    set gaTransform(current,valueList) [GetTransformValues $transformID]
    tkuRefreshEntryNotify $gaWidget(transformProperties,labelEntry)
    set gaTransform(current,isRegistration) \
	[IsTransformRegistration $transformID]

    if { $gaTransform(current,isRegistration) } {

	set gaTransform(curernt,regSource) \
	    [GetTransformRegistrationSource $transformID]
	set gaTransform(curernt,regDest) \
	    [GetTransformRegistrationDest $transformID]
	
	# Select the items in the menu.
	$gaWidget(transformProperties,regSourceMenu) config -disablecallback 1
	$gaWidget(transformProperties,regSourceMenu) config \
	    -value $gaTransform(curernt,regSource)
	$gaWidget(transformProperties,regSourceMenu) config -disablecallback 0
	
	$gaWidget(transformProperties,regDestMenu) config -disablecallback 1
	$gaWidget(transformProperties,regDestMenu) config \
	    -value $gaTransform(curernt,regDest)
	$gaWidget(transformProperties,regDestMenu) config -disablecallback 0
    }

    # Set the invidual values from the value list.
    for { set nRow 0 } { $nRow < 4 } { incr nRow } {
	for { set nCol 0 } { $nCol < 4 } { incr nCol } {
	    set gaTransform(current,value$nCol-$nRow) \
		[lindex $gaTransform(current,valueList) \
		     [expr ($nRow * 4) + $nCol]]
	    tkuRefreshEntryNotify \
		$gaWidget(transformProperties,value$nCol-$nRow)
	}
    }

    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to the transform ID. Then
    # reenable the callback.
    $gaWidget(transformProperties,menu) config -disablecallback 1
    $gaWidget(transformProperties,menu) config -value $transformID
    $gaWidget(transformProperties,menu) config -disablecallback 0
}


# This builds the transform ID list and populates the menu that selects
# the current transform in the transform props panel, and the menu in the
# view props panel. It should be called whenever a transform is created or
# deleted, or when a lyer is added to or removed from a view.
proc UpdateTransformList {} {
    dputs "UpdateTransformList  "

    global gaTransform
    global gaWidget
    global gaView

    # Get the transform ID list.
    set gaTransform(idList) [GetTransformIDList]

    # First rebuild the transform list in the transform props panel.
    FillMenuFromList $gaWidget(transformProperties,menu) $gaTransform(idList) \
	"GetTransformLabel %s" {} false

    # Reselect the current transformProperties.
    if { [info exists gaTransform(current,id)] && 
	 $gaTransform(current,id) >= 0 } {
	SelectTransformInTransformProperties $gaTransform(current,id)
    }

    # Now rebuild the transform list in the view props panel.
    FillMenuFromList $gaWidget(viewProperties,transformMenu) \
	$gaTransform(idList) "GetTransformLabel %s" {} false

    # Now rebuild the transform list in the collection props panel.
    FillMenuFromList $gaWidget(collectionProperties,transformMenu) \
	$gaTransform(idList) "GetTransformLabel %s" {} false
}

proc UpdateCurrentTransformValueList {} {
    dputs "UpdateCurrentTransformValueList  "

    global gaTransform
    global gaWidget

    set gaTransform(current,valueList) {}

    for { set nRow 0 } { $nRow < 4 } { incr nRow } {
	for { set nCol 0 } { $nCol < 4 } { incr nCol } {
	    lappend gaTransform(current,valueList) \
		$gaTransform(current,value$nCol-$nRow)
	}
    }

    # Change the set button to red to remind the user to click that button.
    $gaWidget(transformProperties,setValuesButton) config -fg red
}

proc ClearSetTransformValuesButton {} {
    dputs "ClearSetTransformValuesButton  "

    global gaWidget

    # Change the set button to normal.
    $gaWidget(transformProperties,setValuesButton) config -fg black
}

proc TransformSourceRegistrationMenuCallback { iCollectionID } {
    global gaTransform

    set gaTransform(current,regSource) $iCollectionID
    SetTransformRegistration
    UpdateCurrentTransformValueList
}

proc TransformDestRegistrationMenuCallback { iCollectionID } {
    global gaTransform

    set gaTransform(current,regDest) $iCollectionID
    SetTransformRegistration
    UpdateCurrentTransformValueList
}

proc SetTransformRegistration {} {
    
    global gaTransform

    if { $gaTransform(current,isRegistration) } {

	TreatTransformAsRegistration $gaTransform(current,id) \
	    $gaTransform(current,regSource) $gaTransform(current,regDest)

    } else {

	TreatTransformAsNative $gaTransform(current,id)
    }
}

# COLOR LUT PROPERTIES FUNCTIONS =========================================

proc LUTPropertiesMenuCallback { iLUTID } {
    dputs "LUTPropertiesMenuCallback  $iLUTID  "

    SelectLUTInLUTProperties $iLUTID
}

proc SelectLUTInLUTProperties { iLUTID } {
    dputs "SelectLUTInLUTProperties  $iLUTID  "

    global gaWidget
    global gaLUT

    # Get the lut properties and load them into the 'current' slots.
    set gaLUT(current,id) $iLUTID
    set gaLUT(current,label) [GetColorLUTLabel $iLUTID]
    tkuRefreshEntryNotify $gaWidget(lutProperties,labelEntry)
    set gaLUT(current,fileName) [GetColorLUTFileName $iLUTID]

     
    # Make sure that this is the item selected in the menu. Disale the
    # callback and set the value of the menu to the lut ID. Then
    # reenable the callback.
    $gaWidget(lutProperties,menu) config -disablecallback 1
    $gaWidget(lutProperties,menu) config -value $iLUTID
    $gaWidget(lutProperties,menu) config -disablecallback 0
}


# This builds the lut ID list and populates the menu that selects
# the current lut in the lut props panel, and the menu in the
# layer props panel. It should be called whenever a transform is created or
# deleted.
proc UpdateLUTList {} {
    dputs "UpdateLUTList  "

    global gaLUT
    global gaWidget
    global gaTool

    # Get the lut ID list.
    set gaLUT(idList) [GetColorLUTIDList] 

    # First rebuild the lut list in the lut props panel.
    FillMenuFromList $gaWidget(lutProperties,menu) $gaLUT(idList) \
	"GetColorLUTLabel %s" {} false

    # Reselect the current lutProperties.
    if { [info exists gaLUT(current,id)] && $gaLUT(current,id) >= 0 } {
	SelectLUTInLUTProperties $gaLUT(current,id)
    }

    # Now rebuild the lut list in the layer props panel.
    FillMenuFromList $gaWidget(layerProperties,lutMenu) $gaLUT(idList) \
	"GetColorLUTLabel %s" {} false

    # Rebuild the list in the ROI props.
    FillMenuFromList $gaWidget(roiProperties,lutMenu) $gaLUT(idList) \
	"GetColorLUTLabel %s" {} false

    # Rebuild the list in voxel editing. Set an LUT here if we don't
    # have one yet.
    FillMenuFromList $gaWidget(toolProperties,voxelLutMenu) $gaLUT(idList) \
	"GetColorLUTLabel %s" {} false
    if { ![info exists gaTool(current,voxelLutID)] } {
	SelectLUTInVoxelEditingStructureListBox 0
    }
}

# LABEL AREA FUNCTIONS ==================================================

proc ShowHideLabelArea { ibShow } {
    dputs "ShowHideLabelArea  $ibShow  "

    global gaWidget

    if { $ibShow } {
	grid $gaWidget(labelArea) \
	    -column $gaWidget(labelArea,column) -row $gaWidget(labelArea,row)
    } else {
	grid remove $gaWidget(labelArea)
    }
}

proc UpdateLabelArea { inArea ilLabelValues } {
    dputs "UpdateLabelArea  $ilLabelValues  "

    global glLabelValues
    set glLabelValues($inArea) $ilLabelValues

    DrawLabelArea
}

proc DrawLabelArea {} {

    global gaWidget
    global glLabelValues
    global tk_version

    foreach nArea {1 2} {

	if { ![info exists glLabelValues($nArea)] } {
	    continue
	}

	# Start with empty lists and arrays.
	set tableX {}
	set tableY {}
	array set normalEntries {}
	array set tableEntries {}

	# If we haven't made the frame for this area, make it.
	set fwTop $gaWidget(labelArea,$nArea).fwTop
	if { [catch {$fwTop config}] } {
	    frame $fwTop
	    pack $fwTop -fill both -expand yes
	}

	# For each label-value pair we have...
	foreach lLabelValue $glLabelValues($nArea) {
	    
	    # Get the label and value. Set the value in a global
	    # variable with the label as the index name.
	    set label [lindex $lLabelValue 0]
	    set value [lindex $lLabelValue 1]
	    set glLabelValues($nArea,"$label",value) $value

	    # Has comma? If so, add it to the list of table
	    # entries. Otherwise add it to the list of normal entries.
	    if { [string first , $label] != -1 } {
		
		# Parse out the x and y labels, split by the
		# comma. Add each to the list of x and y table labels.
		set nComma [string first , $label]
		set sX [string range $label 0 [expr $nComma - 1]]
		set sY [string range $label [expr $nComma + 1] end]

		set tableEntries($sX,$sY) $value
		if { [lsearch $tableX $sX] == -1 } {
		    lappend tableX $sX
		}
		if { [lsearch $tableY $sY] == -1 } {
		    lappend tableY $sY
		}

	    } else {

		set normalEntries($label) $value
	    }
	}

	# If we haven't made the normal label frame, make it.
	set fwNormal $fwTop.fwNormal
	if { [catch {$fwNormal config}] } {
	    frame $fwNormal
	    pack $fwNormal -side top -expand yes -fill x
	}
	# First pack our normal entries.
	foreach label [array names normalEntries] {
	    set fw $fwNormal.fw"$label"
	    set ewLabel $fw.ewLabel
	    set ewValue $fw.ewValue

	    # If we haven't made this frame, make it and pack it.
	    if { [catch {$fw config}] } {
		frame $fw
		pack $fw -side top -expand yes -fill x
	    }

	    # Cap the label to 14 chars if necessary.
	    set zLabel [string length $label]
	    if { $zLabel > 14 } {
		set sFirst [string range $label 0 6]
		set sLast [string range $label [expr $zLabel-6] end]
		set label "${sFirst}...${sLast}"
	    }

	    # If we haven't made a label yet, make one, otherwise just
	    # configure it with this labels contents.
	    if { [catch {$ewLabel config}] } {
		tkuMakeNormalLabel $ewLabel -label $label -width 14
		pack $ewLabel -side left -anchor w
	    } else {
		$ewLabel.lw config -text $label
	    }
		
	    # If we haven't made an entry yet, make one, otherwise
	    # just configure the existing one.
	    if { [catch {$ewValue config}] } {
		set bgColor gray
		catch { set bgColor [tix option get disabled_bg] }

		set sState disabled
		if { $tk_version >= 8.4 } {
		    set sState readonly
		}

		entry $ewValue \
		    -textvariable glLabelValues($nArea,"$label",value) \
		    -font [tkuNormalFont] \
		    -width 18 \
		    -state $sState \
		    -relief flat \
		    -background $bgColor
	    } else {
		$ewValue config \
		    -textvariable glLabelValues($nArea,"$label",value)
		pack $ewValue -side left -anchor w
	    }
	}

	    
	# If we haven't made the table frame, make it.
	set fwTable $fwTop.fwTable
	if { [catch {$fwTable config}] } {
	    frame $fwTable -relief sunken -border 2
	    pack $fwTable -expand yes -fill x
	}

	# These are row headers.
	set nCol 1
	foreach sX $tableX {

	    # Cap the label to 14 chars if necessary.
	    set zLabel [string length $sX]
	    if { $zLabel > 14 } {
		set sFirst [string range $sX 0 6]
		set sLast [string range $sX [expr $zLabel-6] end]
		set sX "${sFirst}...${sLast}"
	    }

	    # If we haven't made the header label, do so, otherwise
	    # just configure it with our contents.
	    set cell $fwTable.lw$nCol-0
	    if { [catch {$cell config}] } {
		tkuMakeNormalLabel $cell -label $sX -justify center
		grid $cell -column $nCol -row 0 -sticky ew
	    } else {
		$cell.lw config -text $sX
	    }
	    grid columnconfigure $fwTable $nCol -weight 1
	    incr nCol
	}
	grid columnconfigure $fwTable 0 -weight 1

	# For each row...
	set maxCol 0
	set maxRow 0
	set nRow 1
	foreach sY $tableY {

	    # This is the row header. If we haven't made the label, do
	    # so, otherwise just configure it.
	    set cell $fwTable.lw0-$nRow
	    catch {
		tkuMakeNormalLabel $cell -label $sY
	    }
	    catch {
		grid $cell -column 0 -row $nRow -sticky ew
	    }
	    catch {
		$cell.lw config -text $sY
	    }

	    # These are all the values in this row. For each, if we
	    # haven't made an entry, do so, otherwise just configure
	    # it.
	    set nCol 1
	    foreach sX $tableX {
		if { [info exists tableEntries($sX,$sY)] } {
		    set cell $fwTable.lw$nCol-$nRow
		    catch {
			set bgColor gray
			catch { set bgColor [tix option get disabled_bg] }
			entry $cell \
			 -textvariable glLabelValues($nArea,"$sX,$sY",value) \
			    -font [tkuNormalFont] \
			    -state disabled \
			    -width 15 \
			    -relief flat \
			    -background $bgColor
		    }
		    catch {
			grid  $cell -column $nCol -row $nRow -sticky ew
		    }
		    catch {
			$cell config \
			    -textvariable glLabelValues($nArea,"$sX,$sY",value)
		    }

		    if { $nCol > $maxCol } { set maxCol $nCol }
		    if { $nRow > $maxRow } { set maxRow $nRow }
		}
		incr nCol
	    }
	    incr nRow
	}

	for { set nCol [expr $maxCol + 1] } { $nCol < 10 } { incr nCol } {
	    for { set nRow 0 } { $nRow < 10 } { incr nRow } {
		catch { grid remove $fwTable.lw$nCol-$nRow }
	    }
	}
	for { set nRow [expr $maxRow + 1] } { $nRow < 10 } { incr nRow } {
	    for { set nCol 0 } { $nCol < 10 } { incr nCol } {
		catch { grid remove $fwTable.lw$nCol-$nRow }
	    }
	}


	# Delete lists and arrays.
	unset tableX
	unset tableY
	array unset normalEntries
	array unset tableEntries
    }
}

proc UpdateCursorLabelArea {} {
    global gaView
    global gaWidget

    # Update cursor.
    set err [catch { 
	set labelValues [GetLabelValuesSet $gaView(current,id) cursor]
	UpdateLabelArea $gaWidget(labelArea,nCursorArea) $labelValues
    } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return }
}

# PREFS DIALOG =========================================================

proc DoPrefsDlog {} {
    global gaDialog
    global gaPrefs
    
    set wwDialog .prefs
    if { [tkuCreateDialog $wwDialog "Preferences" {-borderwidth 10}] } {

	set fwKeys     $wwDialog.fwKeys
	set fwButtons  $wwDialog.fwButtons

	frame $fwKeys

	foreach {sKey sLabel} {
	    KeyMoveViewLeft   "Move View Left"
	    KeyMoveViewRight  "Move View Right"
	    KeyMoveViewUp     "Move View Up"
	    KeyMoveViewDown   "Move View Down"
	    KeyMoveViewIn     "Move View In"
	    KeyMoveViewOut    "Move View Out"
	    KeyZoomViewIn     "Zoom View In"
	    KeyZoomViewOut    "Zoom View Out"
	    KeyMouseButtonOne "Mouse Click (button one)"
	    KeyMouseButtonTwo "Mouse Click (button two)"
	    KeyMouseButtonThree "Mouse Click (button three)"
	    KeyInPlaneX       "Change view to x axis in-plane"
	    KeyInPlaneY       "Change view to y axis in-plane"
	    KeyInPlaneZ       "Change view to z axis in-plane"
	    KeyShuffleLayers  "Shuffle layers in a view"
	} {
   
	    tkuMakeEntry $fwKeys.fw$sKey \
		-label $sLabel -width 8 -font [tkuNormalFont] \
		-labelwidth 30 \
		-variable gaPrefs($sKey) \
		-command "SetPreferencesValue $sKey \$gaPrefs($sKey)" \
		-notify 1

	    pack $fwKeys.fw$sKey \
		-side top -fill x -expand yes
	}
	

	tkuMakeCloseButton $fwButtons $wwDialog
	
	pack $fwKeys $fwButtons \
	    -side top       \
	    -expand yes     \
	    -fill x         \
	    -padx 5         \
	    -pady 5
    }
}

# TASK AREA ==============================================================

proc NewTask { args } {
    global gaTask

    if { [info exists gaTask(going)] && $gaTask(going) } {
	puts "task already exists!!"
	return
    }

    # set default arguments for all fields
    set aArgs(-title) ""
    set aArgs(-text) ""
    set aArgs(-meter) false
    set aArgs(-buttons) {}

    # Set arg items.
    array set aArgs $args

    set gaTask(label) $aArgs(-text)
    set gaTask(useMeter) $aArgs(-meter)
    if { $gaTask(useMeter) } {
	set gaTask(progress) "Progress: 0%"
    }

    set nButton 0
    foreach btn $aArgs(-buttons) {
	# Configure and pack our buttons, up to 5 of them.
	if { $nButton < 5 } {
	    $gaTask(buttonFrame).bw$nButton config -text $btn \
		-command "TaskCallback \"$btn\""
	    pack $gaTask(buttonFrame).bw$nButton \
		-side left -anchor e
	    incr nButton
	}
    }
    set gaTask(numButtons) $nButton

    set gaTask(callbacks) {}
    set gaTask(percent) 0

    set gaTask(going) 1
}

proc TaskCallback { isButton } {
    global gaTask

    lappend gaTask(callbacks) $isButton
}

proc UpdateTask { args } {
    global gaTask

    # set default arguments for all fields
    set aArgs(-text) $gaDialog(current,text)
    set aArgs(-percent) $gaDialog(current,percent)

    # Set arg items.
    array set aArgs $args

    set gaTask(label) $aArgs(-text)
    set gaTask(percent) $aArgs(-percent)

    if { $gaTask(useMeter) } {
	set gaDialog(progress) "Progress: $gaTask(percent)"
    }
}

proc CheckTaskForButtons {} {
    global gaTask

    set lCallbacks $gaTask(callbacks)
    set gaTask(callbacks) {}
    return $lCallbacks
}

proc EndTask {} {
    global gaTask

    # Set our labels back to a default.
    set gaTask(label) "Ready."
    set gaTask(progress) ""

    # Unpack our buttons.
    for { set nButton 0 } { $nButton < $gaTask(numButtons) } { incr nButton } {
	pack forget $gaTask(buttonFrame).bw$nButton
    }

    set gaTask(going) 0
}

proc SetStatusBarText { isText } {
    global gaTask

    set gaTask(label) $isText
}

# VIEW CONFIGURATION ==================================================

proc SetLayerInAllViewsInFrame { iFrameID iLayerID } {
    dputs "SetLayerInAllViewsInFrame  $iFrameID $iLayerID  "

    global gaView

    # For each view...
    set err [catch { set cRows [GetNumberOfRowsInFrame $iFrameID] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return }
    for { set nRow 0 } { $nRow < $cRows } { incr nRow } {
	
	set err [catch { 
	    set cCols [GetNumberOfColsAtRowInFrame $iFrameID $nRow]
	} sResult]
	if { 0 != $err } { tkuErrorDlog $sResult; return }
	
	for { set nCol 0 } { $nCol < $cCols } { incr nCol } {
	    
	    set err [catch { 
		set viewID [GetViewIDFromFrameColRow $iFrameID $nCol $nRow] 
	    } sResult]
	    if { 0 != $err } { tkuErrorDlog $sResult; return }

	    # Get the first unused draw level and add the layer to the
	    # view at that level.
	    set err [catch { 
		set level [GetFirstUnusedDrawLevelInView $viewID] } sResult]
	    if { 0 != $err } { tkuErrorDlog $sResult; return }

	    set err [catch {
		SetLayerInViewAtLevel $viewID $iLayerID $level } sResult]
	    if { 0 != $err } { tkuErrorDlog $sResult; return }

	    # That might have changed view properties, so let's
	    # update.
	    if { $gaView(current,id) >= 0 } {
		SelectViewInViewProperties $viewID
	    }
       }
    }
    
    UpdateLayerList
}

proc FillMenuFromList { imw ilEntries iLabelFunction ilLabels ibNone  } {

    set savedValue [$imw cget -value]

    # Disable callback.
    $imw config -disablecallback 1
    
    # Delete all the entries and add ones for all the IDs in the
    # ID list. Also add a command for 'none' with index of -1.
    set lEntries [$imw entries]
    foreach entry $lEntries { 
	$imw delete $entry
    }
    
    if { $ibNone } {
	$imw add command -1 -label "None"
    }

    set nEntry 0
    foreach entry $ilEntries {

	if { $iLabelFunction != "" } {
	    regsub -all %s $iLabelFunction $entry sCommand
	    set sLabel [eval $sCommand]
	}

	if { $ilLabels != {} } {
	    set sLabel [lindex $ilLabels $nEntry]
	}

	$imw add command $entry -label $sLabel
	incr nEntry
    }
    
    if { [lsearch $ilEntries $savedValue] != -1 } {
	$imw config -value $savedValue
    }

    # Renable the callback.
    $imw config -disablecallback 0
}

proc ShowHideConsole { ibShow } {
    global gaWidget
    global gaView

    if { $ibShow } {

	grid $gaWidget(tkcon) -sticky ews \
	    -column $gaWidget(tkcon,column) -row $gaWidget(tkcon,row) \
	    -columnspan 2

    } else {
	
	grid forget $gaWidget(tkcon)
    }

    # Make sure our visible var is set correctly.
    set gaView(tkcon,visible) $ibShow
}

proc ZoomViewIn { } {
    global gaView
    
    set zoomLevel [GetViewZoomLevel $gaView(current,id)]
    SetViewZoomLevel $gaView(current,id) [expr $zoomLevel * 2]
}

proc ZoomViewOut { } {
    global gaView
    
    set zoomLevel [GetViewZoomLevel $gaView(current,id)]
    SetViewZoomLevel $gaView(current,id) [expr $zoomLevel / 2]
}

# DATA LOADING =====================================================

proc MakeVolumeCollectionUsingTemplate { iColID } {
    dputs "MakeVolumeCollectionUsingTemplate  $iColID  "


    set err [catch { set colID [MakeDataCollection Volume] } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return -1 }

    set err [catch { MakeVolumeUsingTemplate $colID $iColID } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return -1 }

    # Get a good name for the collection.
    set sLabel "New Volume"
    
    set err [catch { SetCollectionLabel $colID $sLabel } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return -1 }

    return $colID
}

proc MakeVolumeCollection { ifnVolume } {
    dputs "MakeVolumeCollection  $ifnVolume  "


    set err [catch { set colID [MakeDataCollection Volume] } sResult]
    if { 0 != $err } { error "$sResult" }

    set err [catch { SetVolumeCollectionFileName $colID $ifnVolume } sResult]
    if { 0 != $err } { error "$sResult" }

    set err [catch { LoadVolumeFromFileName $colID } sResult]
    if { 0 != $err } { error "$sResult" }

    # Get a good name for the collection.
    set sLabel [ExtractLabelFromFileName $ifnVolume]
    
    set err [catch { SetCollectionLabel $colID $sLabel } sResult]
    if { 0 != $err } { error "$sResult" }

    return $colID
}

proc MakeSurfaceCollection { ifnSurface } {
    dputs "MakeSurfaceCollection  $ifnSurface  "


    set err [catch { set colID [MakeDataCollection Surface] } sResult]
    if { 0 != $err } { error "$sResult" }

    set err [catch { SetSurfaceCollectionFileName $colID $ifnSurface } sResult]
    if { 0 != $err } { error "$sResult" }

    set err [catch { LoadSurfaceFromFileName $colID } sResult]
    if { 0 != $err } { error "$sResult" }

    # Get a good name for the collection.
    set sLabel [ExtractLabelFromFileName $ifnSurface]
    
    set err [catch { SetCollectionLabel $colID $sLabel } sResult]
    if { 0 != $err } { error "$sResult" }

    return $colID
}

proc Make2DMRILayer { isLabel } {
    dputs "Make2DMRILayer  $isLabel  "
    global gaTool

    set err [catch { set layerID [MakeLayer 2DMRI] } sResult]
    if { 0 != $err } { error "$sResult" }

    set err [catch { SetLayerLabel $layerID $isLabel } sResult]
    if { 0 != $err } { error "$sResult" }

    # Make this new layer the target layer.
    SetToolTargetLayer $gaTool(current,id) $layerID

    UpdateLayerList

    return $layerID
}

proc Make2DMRISLayer { isLabel } {
    dputs "Make2DMRISLayer  $isLabel  "


    set err [catch { set layerID [MakeLayer 2DMRIS] } sResult]
    if { 0 != $err } { error "$sResult" }

    set err [catch { SetLayerLabel $layerID $isLabel } sResult]
    if { 0 != $err } { error "$sResult" }

    UpdateLayerList

    return $layerID
}

proc NewVolume { iTemplateID ibCreateLayer iFrameIDToAdd } {
    dputs "NewVolume  $iTemplateID $ibCreateLayer $iFrameIDToAdd  "

    set err [catch { 
	set colID [MakeVolumeCollectionUsingTemplate $iTemplateID] 
    } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return }

    if { $ibCreateLayer } {

	set sLabel [GetCollectionLabel $colID]

	set layerID [Make2DMRILayer "$sLabel"]

	set err [catch {
	    Set2DMRILayerVolumeCollection $layerID $colID } sResult]
	if { 0 != $err } { tkuErrorDlog $sResult; return }
	
	if { $iFrameIDToAdd != -1 } {
	    SetLayerInAllViewsInFrame $iFrameIDToAdd $layerID
	}

	UpdateCollectionList
	SelectCollectionInCollectionProperties $colID
	SelectLayerInLayerProperties $layerID
    }

    # Create a new ROI for this collection.
    set roiID [NewCollectionROI $colID]
    SetROILabel $roiID "New ROI"
    SetROIType $roiID free
    SetROIColor $roiID 0 0 255
    UpdateROIList
    SelectROIInROIProperties $roiID
    
    SetStatusBarText "Created new volume."
}

proc LoadVolume { ifnVolume ibCreateLayer iFrameIDToAdd } {
    dputs "LoadVolume  $ifnVolume $ibCreateLayer $iFrameIDToAdd  "


    set err [catch { set fnVolume [FindFile $ifnVolume] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    set err [catch { set colID [MakeVolumeCollection $fnVolume] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    if { $ibCreateLayer } {

	set sLabel [ExtractLabelFromFileName $fnVolume]

	set layerID [Make2DMRILayer "$sLabel"]

	set err [catch {
	    Set2DMRILayerVolumeCollection $layerID $colID } sResult]
	if { 0 != $err } { tkuErrorDlog $sResult; return -1 }
	
	if { $iFrameIDToAdd != -1 } {
	    SetLayerInAllViewsInFrame $iFrameIDToAdd $layerID
	}

	UpdateCollectionList
	SelectCollectionInCollectionProperties $colID
	SelectLayerInLayerProperties $layerID
    }

    # Create a new ROI for this collection.
    set roiID [NewCollectionROI $colID]
    SetROILabel $roiID "New ROI"
    SetROIType $roiID free
    SetROIColor $roiID 0 0 255
    UpdateROIList
    SelectROIInROIProperties $roiID
    

    # Add this directory to the shortcut dirs if it isn't there already.
    AddDirToShortcutDirsList [file dirname $ifnVolume]

    SetStatusBarText "Loaded $ifnVolume."

    return $layerID
}

proc LoadSurface { ifnSurface ibCreateLayer iFrameIDToAdd } {
    dputs "LoadSurface  $ifnSurface $ibCreateLayer $iFrameIDToAdd  "

    set layerID -1

    set err [catch { set fnSurface [FindFile $ifnSurface] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    set err [catch { set colID [MakeSurfaceCollection $fnSurface] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    if { $ibCreateLayer } {

	set sLabel [ExtractLabelFromFileName $fnSurface]

	set layerID [Make2DMRISLayer "$sLabel"]

	set err [catch {
	    Set2DMRISLayerSurfaceCollection $layerID $colID } sResult]
	if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }
	
	if { $iFrameIDToAdd != -1 } {
	    SetLayerInAllViewsInFrame $iFrameIDToAdd $layerID
	}

	UpdateCollectionList
	SelectCollectionInCollectionProperties $colID
	SelectLayerInLayerProperties $layerID
    }

    # Add this directory to the shortcut dirs if it isn't there already.
    AddDirToShortcutDirsList [file dirname $ifnSurface]

    SetStatusBarText "Loaded $ifnSurface."
    
    return $layerID
}

proc LoadTransform { ifnLTA } {
    dputs "LoadTransform"
    
    set err [catch { set fnTransform [FindFile $ifnLTA] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    set err [catch { set transformID [MakeNewTransform] } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    set sLabel [ExtractLabelFromFileName $fnTransform]

    SetTransformLabel $transformID $sLabel

    UpdateTransformList

    set err [catch {
	LoadTransformFromLTAFile $transformID $fnTransform } sResult]
    if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }

    SelectTransformInTransformProperties $transformID

    SetStatusBarText "Loaded $ifnLTA."

    return $transformID
}

proc DoSave {} {
    dputs "DoSave "

    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Volume" } {
	
	tkuDoFileDlog -title "Save Volume" \
	    -prompt1 "Will save the volume \"$gaCollection(current,label)\" as\n $gaCollection(current,fileName)" \
	    -type1 note \
	    -okCmd { 
		SaveVolume $gaCollection(current,id)
	    }
	
    } else {
	tkuErrorDlog "You must first select a volume to save. Please select one in the data collections panel."
    }
}

proc DoNewVolumeDlog {} {
    dputs "DoNewVolumeDlog  "

    global gaROI
    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Volume" } {

	tkuDoFileDlog -title "New Volume" \
	    -prompt1 "Will make a new volume using volume \"$gaCollection(current,label)\" as a template." \
	    -type1 note \
	    -type2 checkbox \
	    -prompt2 "Automatically add new layer to all views" \
	    -defaultvalue2 1 \
	    -okCmd { 
		set frameID -1
		if { %s2 } {
		    set frameID $gFrameWidgetToID($gaWidget(scubaFrame))
		}
		NewVolume $gaCollection(current,id) 1 $frameID
	    }
	
    } else {
	tkuErrorDlog "You must first select a volume to use as a template. Please select one in the data collections panel."
    }
}

proc DoLoadVolumeDlog {} {
    dputs "DoLoadVolumeDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Load Volume" \
	-prompt1 "Load Volume: " \
	-defaultdir1 [GetDefaultFileLocation LoadVolume] \
	-type2 checkbox \
	-prompt2 "Automatically add new layer to all views" \
	-defaultvalue2 1 \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    set frameID -1
	    if { %s2 } {
		set frameID $gFrameWidgetToID($gaWidget(scubaFrame))
	    }
	    LoadVolume %s1 1 $frameID
	}
}

proc DoLoadSurfaceDlog {} {
    dputs "DoLoadSurfaceDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Load Surface" \
	-prompt1 "Load Surface: " \
	-defaultdir1 [GetDefaultFileLocation LoadSurface] \
	-type2 checkbox \
	-prompt2 "Automatically add new layer to all views" \
	-defaultvalue2 1 \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    set frameID -1
	    if { %s2 } {
		set frameID $gFrameWidgetToID($gaWidget(scubaFrame))
	    }
	    LoadSurface %s1 1 $frameID
	}
}

proc DoLoadPatchDlog {} {
    dputs "DoLoadPatchDlog  "

    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Surface" } {

	tkuDoFileDlog -title "Load Patch Into Surface" \
	    -prompt1 "Will load a patch into surface \"$gaCollection(current,label)\"." \
	    -type1 note \
	    -prompt2 "Load Patch: " \
	    -defaultdir2 [GetDefaultFileLocation LoadPatch] \
	    -okCmd {
		set err [catch { set fnPatch [FindFile %s2] } sResult]
		if { 0 != $err } { tkuErrorDlog "$sResult"; return -1 }
		LoadSurfacePatch $gaCollection(current,id) $fnPatch
		RedrawFrame [GetMainFrameID]
	    }
	
    } else {
	tkuErrorDlog "You must first select a surface into which to load the patch. Please select one in the data collections panel."
    }
}

proc DoSaveAsDlog {} {
    dputs "DoSaveAsDlog  "

    global glShortcutDirs
    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Volume" } {

	tkuDoFileDlog -title "Save Volume As" \
	    -prompt1 "Will save volume \"$gaCollection(current,label)\"." \
	    -type1 note \
	    -prompt2 "This sets the volume's file name and saves it." \
	    -type2 note \
	    -prompt3 "Save Volume As: " \
	    -defaultvalue3 [GetDefaultFileLocation SaveVolume] \
	    -defaultdir3 [GetDefaultFileLocation SaveVolume] \
	    -shortcutdirs [list $glShortcutDirs] \
	    -okCmd { 
		set err [catch {
		    SetVolumeCollectionFileName $gaCollection(current,id) %s3
		    SaveVolume $gaCollection(current,id)
		} sResult]
		if { 0 != $err } { tkuErrorDlog $sResult }
	    }
	
    } else {
	tkuErrorDlog "You must first select a volume to save. Please select one in the data collections panel."
    }
}


proc DoSaveCopyAsDlog {} {
    dputs "DoSaveCopyAsDlog  "

    global glShortcutDirs
    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Volume" } {

	tkuDoFileDlog -title "Save Copy of Volume" \
	    -prompt1 "Will save a copy of volume \"$gaCollection(current,label)\"." \
	    -type1 note \
	    -prompt2 "This saves the volume somewhere but doesn't change its file name." \
	    -type2 note \
	    -prompt3 "Save Volume: " \
	    -defaultvalue3 [GetDefaultFileLocation SaveVolume] \
	    -defaultdir3 [GetDefaultFileLocation SaveVolume] \
	    -shortcutdirs [list $glShortcutDirs] \
	    -okCmd { 
		set err [catch {
		    SaveVolumeWithFileName $gaCollection(current,id) %s3
		} sResult]
		if { 0 != $err } { tkuErrorDlog $sResult }
	    }
	
    } else {
	tkuErrorDlog "You must first select a volume to use as a template. Please select one in the data collections panel."
    }
}


proc DoSaveLabelDlog {} {
    dputs "DoSaveLabelDlog  "

    global glShortcutDirs
    global gaROI
    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 } {

	if { [info exists gaROI(current,id)] &&
	     $gaROI(current,id) >= -1 } {
	    
	    tkuDoFileDlog -title "Save Label" \
		-prompt1 "Will save ROI \"$gaROI(current,label)\" from data collection \"$gaCollection(current,label)\"" \
		-type1 note \
		-prompt2 "Save Label: " \
		-defaultvalue2 [GetDefaultFileLocation SaveLabel] \
		-defaultdir2 [GetDefaultFileLocation SaveLabel] \
		-shortcutdirs [list $glShortcutDirs] \
		-okCmd { 
		    set err [catch {
			WriteVolumeROIToLabel $gaCollection(current,id) \
			    $gaROI(current,id) %s2
		    } sResult]
		    if { 0 != $err } { tkuErrorDlog $sResult }
		}
	    
	} else {
	    tkuErrorDlog "No ROI is selected. Make sure you have selected one in the Data Collections panel."
	}
	
    } else {
	
	 tkuErrorDlog "There are no data collections. Load some data and try again."

     }
 }


proc DoLoadLabelDlog {} {
    dputs "DoLoadLabelDlog  "

    global glShortcutDirs
    global gaCollection

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 } {

	tkuDoFileDlog -title "Load Label" \
	    -prompt1 "Will create a new ROI for collection \"$gaCollection(current,label)\"" \
	    -type1 note \
	    -prompt2 "Load Label: " \
	    -defaultdir2 [GetDefaultFileLocation LoadLabel] \
	    -defaultvalue2 [GetDefaultFileLocation LoadLabel] \
	    -shortcutdirs [list $glShortcutDirs] \
	    -okCmd { 
		set err [catch {
		    set roiID [NewVolumeROIFromLabel \
				   $gaCollection(current,id) %s2]
		} sResult]
		if { 0 != $err } { 
		    tkuErrorDlog $sResult 
		} else {
		    SetROILabel $roiID [file tail %s2]
		    UpdateROIList
		    SelectROIInROIProperties $roiID
		    RedrawFrame [GetMainFrameID]
		}
	    }
	
    } else {
	
	tkuErrorDlog "There are no data collections. Load some data and try again."
	
     }
 }


 proc DoExportROIsDlog {} {
     dputs "DoExportROIsDlog"

     global glShortcutDirs
     global gaCollection

     if { [info exists gaCollection(current,id)] &&
	  $gaCollection(current,id) >= -1 } {

	 tkuDoFileDlog -title "Export Segmentation" \
	     -prompt1 "Will export all structure ROIs from data collection \"$gaCollection(current,label)\"" \
	     -type1 note \
	     -prompt2 "Save Volume: " \
	     -defaultdir2 [GetDefaultFileLocation ExportSegmentation] \
	     -defaultvalue2 [GetDefaultFileLocation ExportSegmentation] \
	     -shortcutdirs [list $glShortcutDirs] \
	     -okCmd { 
		 set err [catch {
		     WriteVolumeROIsToSegmentation \
			 $gaCollection(current,id) %s2
		 } sResult]
		 if { 0 != $err } { tkuErrorDlog $sResult }
	     }

     } else {
	 tkuErrorDlog "There are no data collections. Load some data and try again."
     }

}

proc DoLoadPathsDlog {} {
    dputs "DoLoadPathsDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Load Paths" \
	-prompt1 "Load Paths: " \
	-defaultdir1 [GetDefaultFileLocation Paths] \
	-defaultvalue1 [GetDefaultFileLocation Paths] \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    ReadPathFile %s1
	    RedrawFrame [GetMainFrameID]
	    SetStatusBarText "Loaded paths from %s1"
	}
}

proc DoSavePathsDlog {} {
    dputs "DoSavePathsDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Save Paths" \
	-prompt1 "Save Paths: " \
	-defaultdir1 [GetDefaultFileLocation Paths] \
	-defaultvalue1 [GetDefaultFileLocation Paths] \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    WritePathFile %s1
	    SetStatusBarText "Wrote paths to %s1"
	}
}

proc DoLoadTransformDlog {} {
    dputs "DoLoadTransformDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Load Transform" \
	-prompt1 "Load Transform: " \
	-defaultdir1 [GetDefaultFileLocation Transform] \
	-defaultvalue1 [GetDefaultFileLocation Transform] \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    LoadTransform %s1
	}
}

proc DoSaveTIFFDlog {} {
    dputs "DoSaveTIFFDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Save TIFF Capture" \
	-prompt1 "Save TIFF: " \
	-defaultdir1 [GetDefaultFileLocation TIFF] \
	-defaultvalue1 [GetDefaultFileLocation TIFF] \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    set err [catch {
		CaptureFrameToFile [GetMainFrameID] %s1
	    } sResult]
	    if { 0 != $err } { tkuErrorDlog $sResult }
	}
}

proc DoExportMarkersToControlPointsDlog {} {
    dputs "DoExportMarkersToControlPointsDlog "

    global gaCollection
    global glShortcutDirs

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Volume" } {
	
	tkuDoFileDlog -title "Export Markers to Control Points" \
	    -prompt1 "Will save the markers as control points using \n \"$gaCollection(current,label)\":" \
	    -defaultdir1 [GetDefaultFileLocation ControlPoints] \
	    -defaultvalue1 [file join [GetDefaultFileLocation ControlPoints] control.dat]\
	    -shortcutdirs [list $glShortcutDirs] \
	    -okCmd { 
		set err [catch { 
		    ExportMarkersToControlPoints $gaCollection(current,id) %s1
		} sResult]
		if { $err != 0 } { tkuErrorDlog $sResult; return }
		SetStatusBarText "Exported control points."
	    }
	
    } else {
	tkuErrorDlog "You must first select a volume. Please select one in the data collections panel."
    }
}

proc DoImportMarkersFromControlPointsDlog {} {
    dputs "DoImportMarkersFromControlPointsDlog  "

    global gaCollection
    global gaWidget
    global glShortcutDirs

    if { [info exists gaCollection(current,id)] &&
	 $gaCollection(current,id) >= -1 &&
	 "$gaCollection(current,type)" == "Volume" } {

	tkuDoFileDlog -title "Import Markers from Control Points" \
	    -prompt1 "Will import control points as markers using volume\n \"$gaCollection(current,label)\":" \
	    -defaultdir1 [GetDefaultFileLocation ControlPoints] \
	    -defaultvalue1 [file join [GetDefaultFileLocation ControlPoints] control.dat]\
	    -shortcutdirs [list $glShortcutDirs] \
	    -okCmd { 
		set err [catch {
		   ImportMarkersFromControlPoints $gaCollection(current,id) %s1
		} sResult]
		if { $err != 0 } { tkuErrorDlog $sResult; return }
		set gaView(numMarkers) [GetNumberOfViewMarkers]
		tkuRefreshEntryNotify $gaWidget(toolProperties,numMarkersEntry)
		SetStatusBarText "Imported control points."	    }
	
    } else {
	tkuErrorDlog "You must first select a volume. Please select one in the data collections panel."
    }
}

proc DoSaveSceneSetupScriptDlog {} {
    dputs "DoSaveSceneSetupScriptDlog  "

    global glShortcutDirs

    tkuDoFileDlog -title "Save Scene Setup Script" \
	-prompt1 "Save Script: " \
	-defaultdir1 [GetDefaultFileLocation Scene] \
	-defaultvalue1 [GetDefaultFileLocation Scene] \
	-shortcutdirs [list $glShortcutDirs] \
	-okCmd { 
	    SaveSceneScript %s1
	}
}

proc SaveSceneScript { ifnScene } {

    global gSubject
    global gaCollection
    global gaLayer
    global gaView
    global gaFrame
    global gaTool
    global gaTransform

    # Open the file
    set f [open $ifnScene w]

    puts $f "\# Scene file generated "
    puts $f "\# by scuba.tcl version \$Id: scuba.tcl,v 1.117 2005/06/01 20:16:03 kteich Exp $"
    puts $f ""

    # Find all the data collections.
    foreach colID $gaCollection(idList) {
	set type [GetCollectionType $colID]
	set sLabel [GetCollectionLabel $colID]
	switch $type {
	    Volume {
		set fnVolume [GetVolumeCollectionFileName $colID]
		set useTransform [GetUseVolumeDataToIndexTransform  $colID]

		puts $f "\#Collection $colID"
		puts $f "set colID \[MakeVolumeCollection \"$fnVolume\"\]"
		puts $f "set layerID \[Make2DMRILayer \"$sLabel\"\]"
		puts $f "Set2DMRILayerVolumeCollection \$layerID \$colID"
	       puts $f "SetUseVolumeDataToIndexTransform \$colID $useTransform"
		puts $f ""
	    }
	}
    }

    if { [info exists gSubject(name)] } {
	puts $f "SetSubjectName \"$gSubject(name)\""
	puts $f ""
    }

    # Get all the layer settings.
    foreach layerID $gaLayer(idList) {
	set type [GetLayerType $layerID]
	set sLabel [GetLayerLabel $layerID]
	set opacity [GetLayerOpacity $layerID]

	puts $f "\# Layer $layerID"
	puts $f "SetLayerLabel $layerID \"$sLabel\""
	puts $f "SetLayerOpacity $layerID $opacity"
	switch $type {
	    2DMRI {
		set colorMapMethod [Get2DMRILayerColorMapMethod $layerID]
		set clearZero [Get2DMRILayerDrawZeroClear $layerID]
		set sampleMethod [Get2DMRILayerSampleMethod $layerID]
		set brightness [Get2DMRILayerBrightness $layerID]
		set contrast [Get2DMRILayerContrast $layerID]
		set lutID [Get2DMRILayerColorLUT $layerID]
		set minVisibleValue [Get2DMRILayerMinVisibleValue $layerID]
		set maxVisibleValue [Get2DMRILayerMaxVisibleValue $layerID]
		set editableROI [Get2DMRILayerEditableROI $layerID]
		set roiOpacity [Get2DMRILayerROIOpacity $layerID]
		puts $f "Set2DMRILayerColorMapMethod $layerID $colorMapMethod"
		puts $f "Set2DMRILayerDrawZeroClear $layerID $clearZero"
		puts $f "Set2DMRILayerSampleMethod $layerID $sampleMethod"
		puts $f "Set2DMRILayerBrightness $layerID $brightness"
		puts $f "Set2DMRILayerContrast $layerID $contrast"
		puts $f "Set2DMRILayerColorLUT $layerID $lutID"
		puts $f "Set2DMRILayerMinVisibleValue $layerID $minVisibleValue"
		puts $f "Set2DMRILayerMaxVisibleValue $layerID $maxVisibleValue"
		puts $f "Set2DMRILayerEditableROI $layerID $editableROI"
		puts $f "Set2DMRILayerROIOpacity $layerID $roiOpacity"
		puts $f ""
	    }
	}
    }

    # Get view settings.
    set viewConfig $gaFrame([GetMainFrameID],viewConfig)
    set numMarkers [GetNumberOfViewMarkers]
    puts $f "\# View config"
    puts $f "SetFrameViewConfiguration [GetMainFrameID]  $viewConfig"
    puts $f "SetNumberOfViewMarkers $numMarkers"
    puts $f ""

    foreach viewID $gaView(idList) {
	puts $f "\# View $viewID"
	set linked [GetViewLinkedStatus $viewID]
	set lockedCursor [GetViewLockOnCursor $viewID]
	set transformID [GetViewTransform $viewID]
	set inPlane [GetViewInPlane $viewID]
	set thPlaneIncX [GetViewThroughPlaneIncrement $viewID x]
	set thPlaneIncY [GetViewThroughPlaneIncrement $viewID y]
	set thPlaneIncZ [GetViewThroughPlaneIncrement $viewID z]
	set rasCenter [GetViewRASCenter $viewID]
	set zoomLevel [GetViewZoomLevel	$viewID]
	puts $f "SetViewLinkedStatus $viewID $linked"
	puts $f "SetViewLockOnCursor $viewID $lockedCursor"
	puts $f "SetViewTransform $viewID $transformID"
	puts $f "SetViewInPlane $viewID $inPlane"
	puts $f "SetViewThroughPlaneIncrement $viewID x $thPlaneIncX"
	puts $f "SetViewThroughPlaneIncrement $viewID y $thPlaneIncY"
	puts $f "SetViewThroughPlaneIncrement $viewID z $thPlaneIncZ"
	puts $f "SetViewRASCenter $viewID $rasCenter"
	puts $f "SetViewZoomLevel $viewID $zoomLevel"
	for { set nLevel 0 } { $nLevel < 10 } { incr nLevel } {
	    set layerID [GetLayerInViewAtLevel $viewID $nLevel]
	    puts $f "SetLayerInViewAtLevel $viewID $layerID $nLevel"
	}
	puts $f ""
    }

    # Transforms.
    foreach transformID $gaTransform(idList) {

	# If it's not the identity transform (because that is created
	# automatically)
	if { $transformID != 0 } {
	    set sLabel [GetTransformLabel $transformID]
	    set valueList [GetTransformValues $transformID]
	    set isRegistration [IsTransformRegistration $transformID]
	    puts $f "\# Transform $transformID"
	    puts $f "set transformID \[MakeNewTransform\]"
	    puts $f "SetTransformLabel \$transformID \"$sLabel\""
	    puts $f "SetTransformValues \$transformID $valueList"
	    if { $isRegistration } {
		set regSource [GetTransformRegistrationSource $transformID]
		set regDest [GetTransformRegistrationDest $transformID]
		puts $f "TreatTransformAsRegistration \$transformID $regSource $regDest"
		
	    }
	    puts $f ""
	}
    }

    # Tool settings.
    set toolID $gaFrame([GetMainFrameID],toolID)
    set target [GetToolTargetLayer $toolID]
    set brushShape [GetToolBrushShape $toolID]
    set brushRadius [GetToolBrushRadius $toolID]
    set brush3D [GetToolBrush3D $toolID]
    set brushOnlyZero [GetToolOnlyBrushZero $toolID]
    set floodSourceCollection [GetToolFloodSourceCollection $toolID]
    set floodStopROIs [GetToolFloodStopAtROIs $toolID]
    set floodStopPaths [GetToolFloodStopAtPaths $toolID]
    set floodFuzziness [GetToolFloodFuzziness $toolID]
    set floodMaxDistance [GetToolFloodMaxDistance $toolID]
    set flood3D [GetToolFlood3D $toolID]
    set floodOnlyZero [GetToolOnlyFloodZero $toolID]
    set newValue [GetToolNewVoxelValue $toolID]
    set eraseValue [GetToolEraseVoxelValue $toolID]
    set edgeBias [GetToolEdgePathEdgeBias $toolID]
    puts $f "\# Tool $toolID"
    puts $f "SetToolTargetLayer $toolID $target"
    puts $f "SetToolBrushShape $toolID $brushShape"
    puts $f "SetToolBrushRadius $toolID $brushRadius"
    puts $f "SetToolBrush3D $toolID $brush3D"
    puts $f "SetToolOnlyBrushZero $toolID $brushOnlyZero"
    puts $f "SetToolFloodSourceCollection $toolID $floodSourceCollection"
    puts $f "SetToolFloodStopAtROIs $toolID $floodStopROIs"
    puts $f "SetToolFloodStopAtPaths $toolID $floodStopPaths"
    puts $f "SetToolFloodFuzziness $toolID $floodFuzziness"
    puts $f "SetToolFloodMaxDistance $toolID $floodMaxDistance"
    puts $f "SetToolFlood3D $toolID $flood3D"
    puts $f "SetToolOnlyFloodZero $toolID $floodOnlyZero"
    puts $f "SetToolNewVoxelValue $toolID $newValue"
    puts $f "SetToolEraseVoxelValue $toolID $eraseValue"
    puts $f "SetToolEdgePathEdgeBias $toolID $edgeBias"
    puts $f ""

    puts $f "UpdateCollectionList"
    puts $f "UpdateLayerList"
    puts $f "UpdateViewList"
    puts $f "UpdateSubjectList"
    puts $f "UpdateTransformList"
    puts $f "UpdateLUTList"


    close $f

    SetStatusBarText "Saved $ifnScene."
}

# A little hack to use when you want the screen to update from a
# script. We schedule a redraw, then use 'after idle' to change a
# value. We wait for the value to change, letting all events process
# until we get an idle.
set DELAY_TIMER 0
proc UpdateFrame { iFrameID } {
    RedrawFrame $iFrameID
    after idle { incr DELAY_TIMER }
    vwait DELAY_TIMER
}



proc MakeHistogramFillWindow {} {
    global gaLayer
    global gaROI

    # Build a list of non-seg volumes for the source layer list.
    set lSourceLayers {}
    foreach layerID $gaLayer(idList) {
	if { [GetLayerType $layerID] == "2DMRI" } {
	    if { [Get2DMRILayerColorMapMethod $layerID] == "grayscale" } {
		set sLabel [GetLayerLabel $layerID]
		lappend lSourceLayers [list $layerID "$sLabel"]
	    }
	}
    }

    if { [llength $lSourceLayers] == 0 } {
	tkuFormattedErrorDlog "Couldn't Make Histogram" \
	    "No anatomical volume layer available as a source." \
	    "To use the histogram fill window, you need a layer with an anatomical (grayscale) volume as the source and a layer with a segmentation volume as the destination."
	return
    }

    # For each of these source layers, get the data and then the ROI
    # list. Build a menu out of these ROIs.
    set lROIs {}
    foreach layerIDLabel $lSourceLayers {
	set layerID [lindex $layerIDLabel 0]
	set volID [Get2DMRILayerVolumeCollection $layerID]
	set lROIID [GetROIIDListForCollection $volID]
	foreach roiID $lROIID {
	    set sLabel [GetROILabel $roiID]
	    lappend lROIs [list $roiID "$sLabel"]
	}
    }

    # Build a list of seg volumes for the dest list.
    set lDestLayers {}
    foreach layerID $gaLayer(idList) {
	if { [GetLayerType $layerID] == "2DMRI" } {
	    if { [Get2DMRILayerColorMapMethod $layerID] == "lut" } {
		set sLabel [GetLayerLabel $layerID]
		lappend lDestLayers [list $layerID "$sLabel"]
	    }
	}
    }
    
    if { [llength $lDestLayers] == 0 } {
	tkuFormattedErrorDlog "Couldn't Make Histogram" \
	    "No segmentation volume layer available as a destination." \
	    "To use the histogram fill window, you need a layer with an anatomical (grayscale) volume as the source and a layer with a segmentation volume as the destination."
	return
    }

    tkuDoFileDlog -title "Histogram Fill" \
	-type1 menu \
	-prompt1 "Source layer (anatomical): " \
	-menu1 $lSourceLayers \
	\
	-type2 checkbox \
	-prompt2 "Use ROI" \
	-defaultvalue2 0 \
	\
	-type3 menu \
	-prompt3 "ROI: " \
	-menu3 $lROIs \
	\
	-type4 menu \
	-prompt4 "Fill layer (segmentation): " \
	-menu4 $lDestLayers \
	\
	-okCmd "MakeHistogramFillWindow2 %s1 %s2 %s3 %s4"
}

proc MakeHistogramFillWindow2 { iSourceLayer ibUseROI iROI iDestLayer } {
    global gaView

    set viewID $gaView(current,id)
    set sourceVol [Get2DMRILayerVolumeCollection $iSourceLayer]
    set roiID -1
    if { $ibUseROI } { set roiID $iROI }
    set destVol [Get2DMRILayerVolumeCollection $iDestLayer]
    set numBins 250
    set lutID [Get2DMRILayerColorLUT $iDestLayer]

    # Get the histogram data from the source volume.
    set err [catch {
	set lResult [GetVolumeHistogramInView $viewID $sourceVol $roiID $numBins]
	set minBinValue [lindex $lResult 0]
	set binIncrement [lindex $lResult 1]
	set lCounts [lindex $lResult 2]
    } sResult]
    if { $err != 0 } {
	tkuErrorDlog "$sResult"
	return
    }

    set min $minBinValue
    set max [expr $minBinValue + ($numBins * $binIncrement)]
    set inc $binIncrement

    if { [llength $lCounts] == 0 ||
	 $min == $max } {
	tkuErrorDlog "No area available to histogram; either there is no slice data visible, or the specified ROI isn't in the view."
	return;
    }

    # Build the CLUT data from the dest color table.
    set lCLUT {}
    set cEntries [GetColorLUTNumberOfEntries $lutID]
    for { set nEntry 0 } { $nEntry < $cEntries } { incr nEntry } {

	set sLabel [GetColorLUTEntryLabel $lutID $nEntry]
	set RGBFloat [GetColorLUTEntryRGB $lutID $nEntry]
	set RGBHex [hl_IntRGBColorToHexString [lindex $RGBFloat 0] [lindex $RGBFloat 2] [lindex $RGBFloat 2]]

	lappend lCLUT [list $nEntry $sLabel \#$RGBHex]
    }

    # Get source label.
    set sTitle "Volume: [GetCollectionLabel $sourceVol]"
    
    # Build the window.
    toplevel .wwHisto
    MakeHistogram .wwHisto.fwTop .wwHisto \
	-title $sTitle \
	-min $min -max $max \
	-increment $inc -numBars [expr $max - $min] \
	-values $lCounts -clut $lCLUT \
	-okCmd "DoHistogramLabel $sourceVol $roiID $destVol"
    pack .wwHisto.fwTop -fill both -expand yes
}

proc DoHistogramLabel { iSourceVol iROIID iDestVol iValueRanges } {
    global gaView

    # This starts the fill.
    BeginValueRangeFillInView $gaView(current,id) \
	$iSourceVol $iROIID $iDestVol

    # Do one fill for each of our ranges.
    foreach valueRange $iValueRanges {
	set begin [lindex $valueRange 0]
	set end [lindex $valueRange 1]
	set value [lindex $valueRange 2]
	DoOneValueRangeFillInView $gaView(current,id) $begin $end $value
    }
    
    # Finish it up. (This actually performs the fill in c code.)
    EndValueRangeFillInView $gaView(current,id)
}

proc DoDataInfoWindow {} {
    global gaDialog
    global gaCollection
    global gaWidget

    set wwDialog .dataInfo
    if { [tkuCreateDialog $wwDialog "Data Info" {-borderwidth 10}] } {

	set fwVolume  $wwDialog.fwVolume
	set fwInfo    $wwDialog.fwInfo
	set fwButtons $wwDialog.fwButtons

	frame $fwVolume
	set owVolume $fwVolume.owVolume

	tixOptionMenu $owVolume \
	    -label "Data Collection:" \
	    -variable blah \
	    -command { DataInfoMenuCallback }
	FillMenuFromList $owVolume \
	    $gaCollection(idList) "GetCollectionLabel %s" {} false

	pack $owVolume -fill x -expand 1


	frame $fwInfo
	set ewInfo $fwInfo.ewInfo

	tixScrolledText $ewInfo -scrollbar y
	set gaWidget(dataInfoText) $ewInfo

	pack $ewInfo -fill both -expand 1


	tkuMakeCloseButton $fwButtons $wwDialog
	
	pack $fwVolume $fwInfo $fwButtons \
	    -side top       \
	    -expand yes     \
	    -fill x         \
	    -padx 5         \
	    -pady 5

	DataInfoMenuCallback 0
    }
}

proc DataInfoMenuCallback { iColID } {
    global gaWidget
    global gaCollection

    [$gaWidget(dataInfoText) subwidget text] \
	config -wrap word -relief ridge -bd 1

    [$gaWidget(dataInfoText) subwidget text] \
	delete 1.0 end

    set sText ""
    set err [catch {

	set sType [GetCollectionType $iColID]
	if { [string match $sType Volume] } {
	    set fnVolume [GetVolumeCollectionFileName $iColID]
	    set sText [exec mri_info $fnVolume]
	} elseif { [string match $sType Surface] } {
	    set fnSurface [GetSurfaceCollectionFileName $iColID]
	    set sText [exec mris_info $fnSurface]
	}
	
    } sResult]
    if { 0 != $err } {
	set sText $sResult
    }
    
    [$gaWidget(dataInfoText) subwidget text] \
	insert end $sText

}

proc DoShowSurfaceVertex {} {
    global gaDialog
    global gaLayer
    global gShowSurfaceVertexInfo

    set wwDialog .showSurfaceVertex
    if { [tkuCreateDialog $wwDialog "Show Vertex" {-borderwidth 10}] } {

	set fwSurface  $wwDialog.fwSurface
	set fwVertex   $wwDialog.fwVertex
	set fwButtons  $wwDialog.fwButtons

	frame $fwSurface
	set owSurface $fwSurface.owSurface

	# Make list of layers with surfaces.
	set lLayers {}
	foreach layerID $gaLayer(idList) {
	    if { [string match [GetLayerType $layerID] 2DMRIS] } {
		lappend lLayers $layerID
	    }
	}

	tixOptionMenu $owSurface \
	    -label "Surface:" \
	    -variable gShowSurfaceVertexInfo(layerID)
	FillMenuFromList $owSurface \
	    $lLayers "GetLayerLabel %s" {} false

	pack $owSurface -fill x -expand 1


	frame $fwVertex
	tkuMakeEntry $fwVertex.ewVertex \
	    -variable gShowSurfaceVertexInfo(vertex) \
	    -command { ShowSurfaceVertexCallback } \
	    -width 10

	pack $fwVertex.ewVertex \
	    -expand yes -fill x


	tkuMakeApplyCloseButtons $fwButtons $wwDialog \
	    -applyLabel "Show" \
	    -applyCmd ShowSurfaceVertexCallback
	
	pack $fwSurface $fwVertex $fwButtons \
	    -side top       \
	    -expand yes     \
	    -fill x         \
	    -padx 5         \
	    -pady 5
    }
}

proc ShowSurfaceVertexCallback {} {
    global gShowSurfaceVertexInfo
    global gaView
    global gaWidget

    set err [catch {
	set lRAS \
	    [Get2DMRISRASCoordsFromVertexIndex \
		 $gShowSurfaceVertexInfo(layerID) \
		 $gShowSurfaceVertexInfo(vertex)]
	
	SetViewRASCursor \
	    [lindex $lRAS 0] [lindex $lRAS 1] [lindex $lRAS 2]

	UpdateCursorLabelArea

	RedrawFrame [GetMainFrameID]
    } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return }
   
}

proc DoFindNearestSurfaceVertex {} {
    global gaDialog
    global gaLayer
    global gFindNearestSurfaceVertexInfo

    set wwDialog .findNearestSurfaceVertex
    if { [tkuCreateDialog $wwDialog "Find Nearest Vertex" {-borderwidth 10}] } {

	set fwSurface  $wwDialog.fwSurface
	set fwButtons  $wwDialog.fwButtons

	frame $fwSurface
	set owSurface $fwSurface.owSurface

	# Make list of layers with surfaces.
	set lLayers {}
	foreach layerID $gaLayer(idList) {
	    if { [string match [GetLayerType $layerID] 2DMRIS] } {
		lappend lLayers $layerID
	    }
	}

	tixOptionMenu $owSurface \
	    -label "Surface:" \
	    -variable gFindNearestSurfaceVertexInfo(layerID)
	FillMenuFromList $owSurface \
	    $lLayers "GetLayerLabel %s" {} false

	pack $owSurface -fill x -expand 1


	tkuMakeApplyCloseButtons $fwButtons $wwDialog \
	    -applyLabel "Find" \
	    -applyCmd FindNearestSurfaceVertexCallback
	
	pack $fwSurface $fwButtons \
	    -side top       \
	    -expand yes     \
	    -fill x         \
	    -padx 5         \
	    -pady 5
    }
}

proc FindNearestSurfaceVertexCallback {} {
    global gFindNearestSurfaceVertexInfo
    global gaView
    global gaWidget

    set err [catch {

	set lCursorRAS [GetViewRASCursor]

	set nClosestVertex \
	    [Get2DMRISNearestVertexIndex \
		 $gFindNearestSurfaceVertexInfo(layerID) \
		 [lindex $lCursorRAS 0] [lindex $lCursorRAS 1] \
		 [lindex $lCursorRAS 2]]

	set lRAS \
	    [Get2DMRISRASCoordsFromVertexIndex \
		 $gFindNearestSurfaceVertexInfo(layerID) \
		 $nClosestVertex]

	SetViewRASCursor \
	    [lindex $lRAS 0] [lindex $lRAS 1] [lindex $lRAS 2]

	UpdateCursorLabelArea
	
	RedrawFrame [GetMainFrameID]
    } sResult]
    if { 0 != $err } { tkuErrorDlog $sResult; return }
   
}

proc DoSetCursorFromEditDatFileDlog {} {
    global gEditDatInfo
    global gaCollection
    global gaDialog

    # Make list of volume and surface collections.
    set lSurfaces {}
    set lVolumes {}
    foreach colID $gaCollection(idList) {
	if { [string match [GetCollectionType $colID] Surface] } {
	    lappend lSurfaces $colID
	}
	if { [string match [GetCollectionType $colID] Volume] } {
	    lappend lVolumes $colID
	}
    }
    
    # If not surfaces, just do the setcursor.
    if { [llength $lSurfaces] == 0 } {
	set gEditDatInfo(useRealRAS) 1
	SetCursorFromEditDatFile
    }

    set wwDialog .setCursorFromEditDatFile
    if { [tkuCreateDialog $wwDialog "Set Cursor from edit.dat" {-borderwidth 10}] } {

	set fwSurface     $wwDialog.fwSurface
	set fwVolume      $wwDialog.fwVolume
	set fwUseRealRAS  $wwDialog.fwUseRealRAS
	set fwButtons     $wwDialog.fwButtons
	
	frame $fwSurface
	set owSurface $fwSurface.owSurface

	tixOptionMenu $owSurface \
	    -label "Surface:" \
	    -variable gEditDatInfo(surfaceID) \
	    -command { EditDataSurfaceMenuCallback }
	FillMenuFromList $owSurface \
	    $lSurfaces "GetCollectionLabel %s" {} false

	pack $owSurface -fill x -expand 1

	frame $fwVolume
	set owVolume $fwVolume.owVolume

	tixOptionMenu $owVolume \
	    -label "Volume:" \
	    -variable gEditDatInfo(volumeID)
	FillMenuFromList $owVolume \
	    $lVolumes "GetCollectionLabel %s" {} false

	pack $owVolume -fill x -expand 1

	set gEditDatInfo(useRealRAS) 0
	frame $fwUseRealRAS
	tkuMakeCheckboxes $fwUseRealRAS.cbUseRealRAS \
	-font [tkuNormalFont] \
	-checkboxes { 
	    {-type text -label "Use Real RAS" 
		-variable gEditDatInfo(useRealRAS) }}

	pack $fwUseRealRAS.cbUseRealRAS


	tkuMakeApplyCloseButtons $fwButtons $wwDialog \
	    -applyLabel "Read" \
	    -applyCmd SetCursorFromEditDatFile
	
	pack $fwSurface $fwVolume $fwUseRealRAS $fwButtons \
	    -side top       \
	    -expand yes     \
	    -fill x         \
	    -padx 5         \
	    -pady 5

	# Set it up with the first surface and volume.
	EditDataSurfaceMenuCallback [lindex $lSurfaces 0]
	set gEditDatInfo(volumeID) [lindex $lVolumes 0]
    }
}

proc EditDataSurfaceMenuCallback { iColID } {
    global gEditDatInfo

    # Get the useRealRAS value from this surface and preset the checkbox.
    set gEditDatInfo(useRealRAS) [GetSurfaceUseRealRAS $iColID]
}

proc SetCursorFromEditDatFile {} {
    global gSubject
    global gaView
    global gaWidget
    global gEditDatInfo

    if { ![info exists gSubject(homeDir)] } {
	tkuErrorDlog "Can't read edit.dat file: No subject is set."
	return
    }

    set fnCursor $gSubject(homeDir)/tmp/edit.dat

    set err [catch {
	set fCursor [open $fnCursor r]
    } sResult]
    if { 0 != $err } { tkuErrorDlog "Couldn't open $fnCursor\n$err"; return }

    set err [catch {
	set lRAS [gets $fCursor]
    } sResult]
    if { 0 != $err } { 
	tkuErrorDlog "Couldn't read from $fnCursor\n$err"
	close $fCursor
	return 
    }

    close $fCursor

    if { [llength $lRAS] != 3 } {
	tkuErrorDlog "Invalid format for $fnCursor: $lRAS"
	return
    }

    # If not useRealRAS, let the volume transform our point here. 
    if { !$gEditDatInfo(useRealRAS) } {

	set lConvertedRAS \
	    [GetRASCoordsFromVolumeSurfaceRAS $gEditDatInfo(volumeID) \
		 [lindex $lRAS 0] [lindex $lRAS 1] [lindex $lRAS 2]]

	set lRAS $lConvertedRAS
    }

    SetViewRASCursor \
	[lindex $lRAS 0] [lindex $lRAS 1] [lindex $lRAS 2]
    RedrawFrame [GetMainFrameID]

    UpdateCursorLabelArea
}

proc DoGenerateReportDlog {} {
    global gaReportInfo
    global gaCollection
    global gaDialog

    # Make list of volume and surface collections.
    set lSurfaces {}
    set lVolumes {}
    foreach colID $gaCollection(idList) {
	if { [string match [GetCollectionType $colID] Surface] } {
	    lappend lSurfaces $colID
	}
	if { [string match [GetCollectionType $colID] Volume] } {
	    lappend lVolumes $colID
	}
    }
    
    # If no volumes, return.
    if { [llength $lVolumes] == 0 } {
	tkuErrorDlog "Must have volumes loaded before generating reports."
	return
    }

    set wwDialog .setCursorFromEditDatFile
    if { [tkuCreateDialog $wwDialog "Generate Report" {-borderwidth 10}] } {

	set fwVolumes $wwDialog.fwVolumes
	set fwData    $wwDialog.fwData
	set fwButtons $wwDialog.fwButtons

	# Make a list of checkboxes of volumes to include in the report.
	tixLabelFrame $fwVolumes \
	    -label "Volumes" \
	    -labelside acrosstop \
	    -options { label.padX 5 }

	set fwVolumesSub [$fwVolumes subwidget frame]

	set gaReport(volumes,list) $lVolumes
	set lCheckboxes {}
	foreach volID $lVolumes {
	    set gaReportInfo(volumes,$volID) 0
	    lappend lCheckboxes \
		[list -type text -label "GetCollectionLabel $volID" \
		 -variable gaReportInfo(volumes,$volID)]
	    lappend gaReportInfo(volumes,list) $volID
	}

	tkuMakeCheckboxes $fwVolumesSub.cbVolumes \
	    -font [tkuNormalFont] \
	    -checkboxes $lCheckboxes

	pack $fwVolumesSub.cbVolumes \
	    -fill both -expand y

	# Make a list of checkboxes for types of information.
	tixLabelFrame $fwData \
	    -label "Data" \
	    -labelside acrosstop \
	    -options { label.padX 5 }

	set fwDataSub [$fwData subwidget frame]

	tkuMakeCheckboxes $fwDataSub.cbData \
	    -font [tkuNormalFont] \
	    -checkboxes {
		{-type test -label "Segmentation Volumes"
		    -variable gaReportInfo(data,segVolumes) }
	    }

	pack $fwDataSub.cbData \
	    -fill both -expand y


	tkuMakeCancelOKButtons $fwButtons $wwDialog \
	    -okCmd GenerateReport
	
	pack $fwVolumes $fwData $fwButtons \
	    -side top       \
	    -expand yes     \
	    -fill x         \
	    -padx 5         \
	    -pady 5
    }
}

proc GenerateReport {} {
    global gaReportInfo

    if { $gaReportInfo(data,segVolumes) } {
	
	foreach volID $gaReportInfo(volumes,list) {

	    # Get a list of segmentation volumes

	}
    }
}

# MAIN =============================================================

set argc [GetArgc]
set argv [GetArgv]

# Source our support files.
foreach sSourceFileName { tkUtils.tcl histolabel.tcl tkcon.tcl } {
    set lPath [list "$env(PWD)" ../scripts]
    if { [info exists env(DEV)] } {
	lappend lPath "$env(DEV)/scripts"
    }
    if { [info exists env(FREESURFER_HOME)] } {
	lappend lPath "$env(FREESURFER_HOME)/lib/tcl"
    }
    set bFound 0
    foreach sPath $lPath {
	if { $bFound == 0 } {
	    set sFullFileName [ file join $sPath $sSourceFileName ]
	    if { [file exists $sFullFileName] } { 
		set nErr [catch { source $sFullFileName } sResult]
		if { $nErr != 0 } {
		    puts "Error sourcing $sFullFileName: $sResult"
		} else {
		    puts "Using $sFullFileName"
		    set bFound 1
		}
	    }
	}
    }    
    if { $bFound == 0 } {
	puts "Couldn't load $sSourceFileName: Not found in $lPath"
    }
}

# Look at our command line args. For some we will want to process and
# exit without bringing up all our windows. For some, we need to bring
# up our windows first. So cache those in lCommands and we'll execute
# them later.
set lCommands {}

set nArg 0
while { $nArg < $argc } {
    set sArg [lindex $argv $nArg]
    set sOption [string range $sArg [expr [string last "-" $sArg]+1] end]
    switch $sOption {
	v - volume {

	    while { [expr ($nArg + 1) < $argc] &&
		    [string range [lindex $argv [expr $nArg+1]] 0 0] != "-" } {
		incr nArg

		set sCurArg [lindex $argv $nArg]
		set fnVolume [lindex $argv $nArg]
		set sLayerArgs ""
		if { [string first : $fnVolume] != -1 } {
		    set fnVolume \
			[string range $sCurArg 0 \
			 [expr [string first : $sCurArg]-1]]
		    set sLayerArgs \
			[string range $sCurArg \
			 [expr [string first : $sCurArg]+1] end]
		}
		lappend lCommands \
		    "set layerID \[LoadVolume $fnVolume 1 \[GetMainFrameID\]\]"
		
		if { $sLayerArgs != "" } {
		    lappend lCommands \
			"set err \[catch {
                          ProcessLayerOptionList \$layerID $sLayerArgs
                         } sResult\]
                         if { 0 != \$err } { tkuErrorDlog \$sResult }"
		}
	    }
	}
	f - surface {
	    incr nArg
	    set fnSurface [lindex $argv $nArg]
	    lappend lCommands "LoadSurface $fnSurface 1 [GetMainFrameID]"
	}
	s - subject {
	    incr nArg
	    set sSubject [lindex $argv $nArg]
	    lappend lCommands "SetSubjectName $sSubject"
	}
	t - transform {
	    incr nArg
	    set fnTransform [lindex $argv $nArg]
	    lappend lCommands "LoadTransform $fnTransform"
	}
	c - script {
	    incr nArg
	    set fnScript [lindex $argv $nArg]
	    lappend lCommands "after 100 { source $fnScript }"
	}
	
	help - default {
	    if {$sOption != "help"} {puts "Option $sOption not recognized."}
	    puts ""
	    puts "Usage: scuba \[OPTION\]..."
	    puts "Data viewer for the FreeSurfer package."
	    puts ""
	    puts "Options:"
	    puts "-s, --subject SUBJECT Set the subject for this session. Environment variable "
	    puts "                      SUBJECTS_DIR should be set."
	    puts "-v, --volume FILE     Load a volume file. Can be a file name or a subdir in"
	    puts "                      the subject's directory specified with -s."
	    puts "-f, --surface FILE    Load a surface file Can be a file name or a subdir in"
	    puts "                      the subject's directory specified with -s."
	    puts "-t, --transform FILE  Load a transform file Can be a file name or a file in"
	    puts "                      the subject's mri/transforms directory specified with -s."
	    puts "-c, --script FILE     Run the tcl script FILE after loading."
	    exit
	}
    }
    incr nArg
}


# Do some startup stuff!
BuildShortcutDirsList
LoadImages


# Make the main window.
set gaWidget(window) .main
toplevel $gaWidget(window)
wm title $gaWidget(window) "scuba"

# Make the tkcon panel. This must be done at this scope because the
# tkcon.tcl script needs access to some global vars.
set gaWidget(tkcon) [frame $gaWidget(window).tkcon -height 40]
::tkcon::Init -root $gaWidget(tkcon) -showmenu 0 -embed 1 -exec ""
tkcon attach main

# Make the areas in the window. Make the scuba frame first because it
# inits stuff that is needed by other areas.
set gaWidget(scubaFrame) [MakeScubaFrame $gaWidget(window)]
set gaWidget(menuBar) [MakeMenuBar $gaWidget(window)]
set gaWidget(toolBar) [MakeToolBar $gaWidget(window)]
set gaWidget(labelArea) [MakeLabelArea $gaWidget(window)]
set gaWidget(properties) [MakePropertiesPanel $gaWidget(window)]
set gaWidget(task) [MakeTaskArea $gaWidget(window)]

# Set the grid coords of our areas and the grid them in.
set gaWidget(menuBar,column)    0; set gaWidget(menuBar,row)    0
set gaWidget(toolBar,column)    0; set gaWidget(toolBar,row)    1
set gaWidget(scubaFrame,column) 0; set gaWidget(scubaFrame,row) 2
set gaWidget(properties,column) 1; set gaWidget(properties,row) 2
set gaWidget(labelArea,column)  0; set gaWidget(labelArea,row)  3
set gaWidget(task,column)       0; set gaWidget(task,row)       4
set gaWidget(tkcon,column)      0; set gaWidget(tkcon,row)      5

grid $gaWidget(menuBar) -sticky ew -columnspan 2 \
    -column $gaWidget(menuBar,column) -row $gaWidget(menuBar,row)
grid $gaWidget(toolBar) -sticky ew -columnspan 2 \
    -column $gaWidget(toolBar,column) -row $gaWidget(toolBar,row)
grid $gaWidget(scubaFrame) \
    -column $gaWidget(scubaFrame,column) -row $gaWidget(scubaFrame,row) \
    -sticky news
grid $gaWidget(properties) -sticky ns \
    -column $gaWidget(properties,column) -row $gaWidget(properties,row) \
    -rowspan 2
grid $gaWidget(labelArea) \
    -column $gaWidget(labelArea,column) -row $gaWidget(labelArea,row) \
    -sticky ew
grid $gaWidget(task) -sticky ews \
    -column $gaWidget(task,column) -row $gaWidget(task,row) \
    -columnspan 2

grid columnconfigure $gaWidget(window) 0 -weight 1
grid columnconfigure $gaWidget(window) 1 -weight 0
grid rowconfigure $gaWidget(window) 0 -weight 0
grid rowconfigure $gaWidget(window) 1 -weight 0
grid rowconfigure $gaWidget(window) 2 -weight 1
grid rowconfigure $gaWidget(window) 3 -weight 0
grid rowconfigure $gaWidget(window) 4 -weight 0
grid rowconfigure $gaWidget(window) 5 -weight 0

wm withdraw .

# Let tkUtils finish up.
tkuFinish

# Make the default color LUTs.
foreach fnLUT {tkmeditColorsCMA tkmeditParcColorsCMA surface_labels.txt Simple_surface_labels2002.txt jeans_labels.txt FreeSurferColorLUT.txt} {
    if { [file exists $env(FREESURFER_HOME)/$fnLUT] } {
	set lutID [MakeNewColorLUT]
	SetColorLUTLabel $lutID "$fnLUT"
	SetColorLUTFileName $lutID [file join $env(FREESURFER_HOME) $fnLUT]
    }
}


# Make the default transform if necessary.
set transformList [GetTransformIDList]
if { [llength $transformList] == 0 } {
    set transformID [MakeNewTransform]
    SetTransformLabel $transformID "Identity"
}

# Set default view configuration and update/initialize the
# menus. Select the view to set everything up.
SetFrameViewConfiguration [GetMainFrameID] c1
UpdateCollectionList
UpdateLayerList
UpdateViewList
UpdateSubjectList
UpdateTransformList
UpdateLUTList
SelectViewInViewProperties 0
SelectTransformInTransformProperties 0
SelectLUTInLUTProperties 0
SelectToolInToolProperties [GetPreferencesValue SelectedTool]

ShowHideConsole $gaView(tkcon,visible)

GetPreferences

MakeScubaFrameBindings [GetMainFrameID]

# Now execute all the commands we cached before.
foreach command $lCommands {
    eval $command
}

# Refresh settings
SelectViewInViewProperties 0
SelectTransformInTransformProperties 0
SelectLUTInLUTProperties 0
SelectToolInToolProperties [GetPreferencesValue SelectedTool]
if { $gaLayer(current,id) >= 0 } {
    SelectLayerInLayerProperties $gaLayer(current,id)
}

# Updates the target layer menu.
SelectToolInToolProperties [GetPreferencesValue SelectedTool]


bind $gaWidget(window) <Destroy> "Quit"
bind $gaWidget(window) <Alt-Key-q> "Quit"
bind $gaWidget(window) <Alt-Key-n> {
    if { $gaView(tkcon,visible) } {
	set gaView(tkcon,visible) 0
    } else {
	set gaView(tkcon,visible) 1
    }
    ShowHideConsole $gaView(tkcon,visible)
}


