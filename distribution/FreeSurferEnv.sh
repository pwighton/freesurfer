#!/bin/bash -p

#############################################################################
# Name:    FreeSurferEnv.sh
# Purpose: Setup the environment to run FreeSurfer/FS-FAST (and FSL)
# Usage:   See help section below
#
# $Id: FreeSurferEnv.sh,v 1.2 2005/09/20 16:49:28 nicks Exp $
#############################################################################

VERSION='$Id: FreeSurferEnv.sh,v 1.2 2005/09/20 16:49:28 nicks Exp $'

## Print help if --help or -help is specified
if [[ "$1" == "--help" || "$1" == "-help" ]]; then
    echo "FreeSurferEnv.sh"
    echo ""
    echo "Purpose: Setup the environment to run FreeSurfer and FS-FAST"
    echo ""
    echo "Usage:"
    echo ""
    echo "1. Create an environment variable called FREESURFER_HOME and"
    echo "   set it to the directory in which FreeSurfer is installed."
    echo "2. From a sh or bash shell or (.login): "
    echo '       source $FREESURFER_HOME/FreeSurferEnv.sh'
    echo "3. There are environment variables that should point to locations"
    echo "   of software or data used by FreeSurfer. If set prior to"
    echo "   sourcing, they will not be changed, but will otherwise be"
    echo "   set to default locations:"
    echo "       FSFAST_HOME"
    echo "       SUBJECTS_DIR"
    echo "       FUNCTIONALS_DIR"
    echo "       MINC_BIN_DIR"
    echo "       MINC_LIB_DIR"
    echo "       GSL__DIR"
    echo "       FSL_DIR"
    echo "4. If NO_MINC is set (to anything), "
    echo "   then all the MINC stuff is ignored."
    echo "5. If NO_FSFAST is set (to anything), "
    echo "   then the startup.m stuff is ignored."
    echo "6. The script will print the final settings for the above "
    echo "   variables as well as any warnings about missing directories."
    echo "   If FS_FREESURFERENV_NO_OUTPUT is set, then no normal output"
    echo "   will be made (only error messages)."
    echo ""
    echo "The most convenient way to use this script is to write another"
    echo "script that sets FREESURFER_HOME and possibly SUBJECTS_DIR for"
    echo "your set-up, as well as NO_MINC, NO_FSFAST, or"
    echo "FS_FREESURFERENV_NO_OUTPUT as appropriate, and then source this"
    echo "script.  See SetUpFreeSurfer.sh for an example."
    return 0;
fi

## Get the name of the operating system
os=`uname -s`
export OS=$os

## Set this environment variable to suppress the output.
if [ -n $FS_FREESURFERENV_NO_OUTPUT ]; then
    output=0
else
    output=1
fi

if [[ $?USER == 0 || $?prompt == 0 ]]; then
    output=0
fi

if [ $output==1 ]; then
    echo "Setting up environment for FreeSurfer/FS-FAST (and FSL)"
    if [[ "$1" = "--version" || \
        "$1" = "--V" || \
        "$1" = "-V" || \
        "$1" = "-v" ]]; then
        echo $VERSION
    fi
fi

## Check if FREESURFER_HOME variable exists, then check if the actual
## directory exists.
if [ -z $FREESURFER_HOME ]; then
    echo "ERROR: environment variable FREESURFER_HOME is not defined"
    echo "       Run the command 'export FREESURFER_HOME <FreeSurferHome>'"
    echo "       where <FreeSurferHome> is the directory where FreeSurfer"
    echo "       is installed."
    return 1;
fi

if [ ! -d $FREESURFER_HOME ]; then
    echo "ERROR: $FREESURFER_HOME "
    echo "       does not exist. Check that this value is correct.";
    return 1;
fi

## Now we'll set directory locations based on FREESURFER_HOME for use
## by other programs and scripts.

## Set up the path. They should probably already have one, but set a
## basic one just in case they don't. Then add one with all the
## directories we just set.  Additions are made along the way in this
## script.
if [ -z $PATH ]; then
    PATH="~/bin:/bin:/usr/bin:/usr/local/bin"
fi

## If FS_OVERRIDE is set, this script will automatically assign
## defaults to all locations. Otherwise, it will only do so if the
## variable isn't already set
if [ -z $FS_OVERRIDE ]; then
    export FS_OVERRIDE=0
fi

if [[ -z $FSFAST_HOME || $FS_OVERRIDE -ne 0 ]]; then
    export FSFAST_HOME=$FREESURFER_HOME/fsfast
fi

if [[ -z $SUBJECTS_DIR  || $FS_OVERRIDE -ne 0 ]]; then
    export SUBJECTS_DIR=$FREESURFER_HOME/subjects
fi

if [[ -z $FUNCTIONALS_DIR  || $FS_OVERRIDE -ne 0 ]]; then
    export FUNCTIONALS_DIR=$FREESURFER_HOME/sessions
fi

if [[ -z $NO_MINC && ( -z $MINC_BIN_DIR  || $FS_OVERRIDE -ne 0 ) ]]; then
    # try to find minc toolkit binaries
    if [ -n $MNI_INSTALL_DIR ]; then
        export MINC_BIN_DIR=$MNI_INSTALL_DIR/bin
    elif [ -e $FREESURFER_HOME/lib/mni/bin ]; then
        export MINC_BIN_DIR=$FREESURFER_HOME/lib/mni/bin
    elif [ -e /usr/pubsw/packages/mni/current/bin ]; then
        export MINC_BIN_DIR=/usr/pubsw/packages/mni/current/bin
    elif [ -e /usr/local/mni/bin ]; then
        export MINC_BIN_DIR=/usr/local/mni/bin
    elif [ -e $FREESURFER_HOME/minc/bin ]; then
        export MINC_BIN_DIR=$FREESURFER_HOME/minc/bin
    fi
fi

if [[ -z $NO_MINC && ( -z $MINC_LIB_DIR  || $FS_OVERRIDE -ne 0 ) ]]; then
    # try to find minc toolkit libraries
    if [ -n $MNI_INSTALL_DIR ]; then
        export MINC_LIB_DIR=$MNI_INSTALL_DIR/lib
    elif [ -e $FREESURFER_HOME/lib/mni/lib ]; then
        export MINC_LIB_DIR=$FREESURFER_HOME/lib/mni/lib
    elif [ -e /usr/pubsw/packages/mni/current/lib ]; then
        export MINC_LIB_DIR=/usr/pubsw/packages/mni/current/lib
    elif [ -e /usr/local/mni/lib ]; then
        export MINC_LIB_DIR=/usr/local/mni/lib
    elif [ -e $FREESURFER_HOME/minc/lib ]; then
        export MINC_LIB_DIR=$FREESURFER_HOME/minc/lib
    fi
fi

if [[ -z $FSL_DIR  || $FS_OVERRIDE -ne 0 ]]; then
    # FSLDIR is the FSL declared location, use that.
    # else try find an installation.
    if [ -n $FSLDIR ]; then
        export FSL_DIR=$FSLDIR
    elif [ -e /usr/pubsw/packages/fsl/current ]; then
        export FSL_DIR=/usr/pubsw/packages/fsl/current
    elif [ -e /usr/local/fsl ]; then
        export FSL_DIR=/usr/local/fsl
    elif [ -e $FREESURFER_HOME/fsl ]; then
        export FSL_DIR=$FREESURFER_HOME/fsl
    elif [ -e /Users/Shared/fsl ]; then
        export FSL_DIR=/Users/Shared/fsl
    fi
fi

export FREESURFER_HOME=$FREESURFER_HOME
export       LOCAL_DIR=$FREESURFER_HOME/local

## Make sure these directories exist.
for d in "$FSFAST_HOME" "$SUBJECTS_DIR"; do
    if [ ! -d $d ]; then
        if [ $output==1 ]; then
            echo "WARNING: $d does not exist"
        fi
    fi
done

if [ $output==1 ]; then
    echo "FREESURFER_HOME $FREESURFER_HOME"
    echo "FSFAST_HOME     $FSFAST_HOME"
    echo "SUBJECTS_DIR    $SUBJECTS_DIR"
fi
if [[ $output==1 && -n $FUNCTIONALS_DIR ]]; then
    echo "FUNCTIONALS_DIR $FUNCTIONALS_DIR"
fi

## Talairach subject in anatomical database.
export FS_TALAIRACH_SUBJECT=talairach


######## --------- Functional Analysis Stuff ----------- #######
if [[ -z $NO_FSFAST ]]; then
    export FMRI_ANALYSIS_DIR=$FSFAST_HOME # backwards compatability
    SUF=~/matlab/startup.m
    if [ ! -e $SUF ]; then
        echo "INFO: $SUF does not exist ... creating"
        mkdir -p ~/matlab
        touch $SUF

        echo "%------------ FreeSurfer FAST ------------------------%" >> $SUF
        echo "fsfasthome = getenv('FSFAST_HOME');"                     >> $SUF
        echo "fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);"       >> $SUF
        echo "path(path,fsfasttoolbox);"                               >> $SUF
        echo "clear fsfasthome fsfasttoolbox;"                         >> $SUF
        echo "%-----------------------------------------------------%" >> $SUF
    fi

    tmp1=`grep FSFAST_HOME $SUF       | wc -l`;
    tmp2=`grep FMRI_ANALYSIS_DIR $SUF | wc -l`;
  
    if [ $tmp1 == 0 -a $tmp2 == 0 ] ; then
        if [ $output == "1" ] ; then
            echo ""
            echo "WARNING: The $SUF file does not appear to be";
            echo "         configured correctly. You may not be able"
            echo "         to run the FS-FAST programs";
            echo "Try adding the following three lines to $SUF"
            echo "----------------cut-----------------------"
            echo "fsfasthome = getenv('FSFAST_HOME');"         
            echo "fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);"
            echo "path(path,fsfasttoolbox);"                        
            echo "clear fsfasthome fsfasttoolbox;"
            echo "----------------cut-----------------------"
            echo ""
        fi
    fi
fi


### ----------- MINC Stuff -------------- ####
if [[ $output==1 && -n $MINC_BIN_DIR ]]; then
    echo "MINC_BIN_DIR    $MINC_BIN_DIR"
fi
if [[ $output==1 && -n $MINC_LIB_DIR ]]; then
    echo "MINC_LIB_DIR    $MINC_LIB_DIR"
fi
if [ -z $NO_MINC ]; then
    if [ -n $MINC_BIN_DIR ]; then
        if [ ! -d $MINC_BIN_DIR ]; then
            if [ $output==1 ]; then
                echo "WARNING: MINC_BIN_DIR '$MINC_BIN_DIR' does not exist.";
            fi
        fi
    else
        if [ $output==1 ]; then
            echo "WARNING: MINC_BIN_DIR not defined."
            echo "         'nu_correct' and other MINC tools"
            echo "         are used by some Freesurfer utilities."
            echo "         Set NO_MINC to suppress this warning."
        fi
    fi
    if [ -n  $MINC_LIB_DIR ]; then
        if [ ! -d $MINC_LIB_DIR ]; then
            if [ $output==1 ]; then
                echo "WARNING: MINC_LIB_DIR '$MINC_LIB_DIR' does not exist.";
            fi
        fi
    else
        if [ $output==1 ]; then
            echo "WARNING: MINC_LIB_DIR not defined."
            echo "         Some Freesurfer utilities rely on the"
            echo "         MINC toolkit libraries."
            echo "         Set NO_MINC to suppress this warning."
        fi
    fi
    ## Set Load library path ##
    if [ -z $LD_LIBRARY_PATH ]; then
        if [ -n $MINC_LIB_DIR ]; then
            export LD_LIBRARY_PATH=$MINC_LIB_DIR
        fi
    else
        if [ -n $MINC_LIB_DIR ]; then
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH":"$MINC_LIB_DIR"
        fi
    fi
    ## nu_correct and other MINC tools require a path to perl
    if [ -z $PERL5LIB ]; then
        if [ -e $MINC_LIB_DIR/../System/Library/Perl/5.8.6 ]; then
            # Max OS X Tiger default:
            export PERL5LIB="$MINC_LIB_DIR/../System/Library/Perl/5.8.6"
        elif [ -e $MINC_LIB_DIR/../System/Library/Perl/5.8.1 ]; then
            # Max OS X Panther default:
            export PERL5LIB="$MINC_LIB_DIR/../System/Library/Perl/5.8.1"
        elif [ -e $MINC_LIB_DIR/perl5/5.8.5 ]; then
            # Linux CentOS4:
            export PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5"
        elif [ -e $MINC_LIB_DIR/perl5/5.8.3 ]; then
            # Linux FC2:
            export PERL5LIB="$MINC_LIB_DIR/perl5/5.8.3"
        elif [ -e $MINC_LIB_DIR/perl5/site_perl/5.8.3 ]; then
            # Linux:
            export PERL5LIB="$MINC_LIB_DIR/perl5/site_perl/5.8.3"
        elif [ -e $MINC_LIB_DIR/5.6.0 ]; then
            # Linux RH7 and RH9:
            export PERL5LIB="$MINC_LIB_DIR/5.6.0"
        fi
    fi
    if [[ $output==1 && -n $PERL5LIB ]]; then
        echo "PERL5LIB        $PERL5LIB"
    fi
fi
if [ -z $NO_MINC ]; then
    if [ -n $MINC_BIN_DIR ]; then
        PATH=$MINC_BIN_DIR:$PATH
    fi
fi


### ----------- GSL (Gnu Scientific Library)  ------------ ####
if [ -d $FREESURFER_HOME/lib/gsl ]; then
    export GSL_DIR=$FREESURFER_HOME/lib/gsl
elif [ -d /usr/pubsw/packages/gsl/current ]; then
    export GSL_DIR=/usr/pubsw/packages/gsl/current
fi
if [ -n $GSL_DIR ]; then
    export PATH=$GSL_DIR/bin:$PATH
    if [ -z $LD_LIBRARY_PATH ]; then
        export LD_LIBRARY_PATH=$GSL_DIR/lib
    else
        export LD_LIBRARY_PATH="$GSL_DIR/lib":"$LD_LIBRARY_PATH"
    fi
    if [ -z $DYLD_LIBRARY_PATH ]; then
        export DYLD_LIBRARY_PATH=$GSL_DIR/lib
    else
        export DYLD_LIBRARY_PATH="$GSL_DIR/lib":"$DYLD_LIBRARY_PATH"
    fi
fi
if [[ $output==1 && -n $GSL_DIR ]]; then
    echo "GSL_DIR         $GSL_DIR"
fi


### ----------- Qt (scuba2 support libraries)  ------------ ####
# look for Qt in common NMR locations, overriding any prior setting
if [ -d $FREESURFER_HOME/lib/qt ]; then
    export QTDIR=$FREESURFER_HOME/lib/qt
elif [ -d /usr/pubsw/packages/qt/current ]; then
    export QTDIR=/usr/pubsw/packages/qt/current
fi
if [ -n $QTDIR ]; then
    export PATH=$QTDIR/bin:$PATH
    if [ -z $LD_LIBRARY_PATH ]; then
        export LD_LIBRARY_PATH=$QTDIR/lib
    else
        export LD_LIBRARY_PATH="$QTDIR/lib":"$LD_LIBRARY_PATH"
    fi
fi
if [[ $output==1 && -n $QTDIR ]]; then
    echo "QTDIR           $QTDIR"
fi


### ----------- Tcl/Tk/Tix/BLT  ------------ ####
if [ -d $FREESURFER_HOME/lib/tcltktixblt/bin ]; then
    PATH=$FREESURFER_HOME/lib/tcltktixblt/bin:$PATH
fi
if [ -d $FREESURFER_HOME/lib/tcltktixblt/lib ]; then
    export TCLLIBPATH=$FREESURFER_HOME/lib/tcltktixblt/lib
    export TCL_LIBRARY=$TCLLIBPATH/tcl8.4
    export TK_LIBRARY=$TCLLIBPATH/tk8.4
    export TIX_LIBRARY=$TCLLIBPATH/tix8.1
    export BLT_LIBRARY=$TCLLIBPATH/blt2.4
    if [ -z $LD_LIBRARY_PATH ]; then
        export LD_LIBRARY_PATH=$TCLLIBPATH
    else
        export LD_LIBRARY_PATH="$TCLLIBPATH":"$LD_LIBRARY_PATH"
    fi
    if [ -z $DYLD_LIBRARY_PATH ]; then
        export DYLD_LIBRARY_PATH=$TCLLIBPATH
    else
        export DYLD_LIBRARY_PATH="$TCLLIBPATH":"$DYLD_LIBRARY_PATH"
    fi
fi
if [[ $output==1 && -n $TCLLIBPATH ]]; then
    echo "TCLLIBPATH      $TCLLIBPATH"
fi


### - Miscellaneous support libraries tiff/jpg/glut (Mac OS only) - ####
if [ -d $FREESURFER_HOME/lib/misc/bin ]; then
    PATH=$FREESURFER_HOME/lib/misc/bin:$PATH
fi
if [ -d $FREESURFER_HOME/lib/misc/lib ]; then
    export MISC_LIB=$FREESURFER_HOME/lib/misc/lib
    if [ -z $LD_LIBRARY_PATH ]; then
        export LD_LIBRARY_PATH=$MISC_LIB
    else
        export LD_LIBRARY_PATH="$MISC_LIB":"$LD_LIBRARY_PATH"
    fi
    if [ -z $DYLD_LIBRARY_PATH ]; then
        export DYLD_LIBRARY_PATH=$MISC_LIB
    else
        export DYLD_LIBRARY_PATH="$MISC_LIB":"$DYLD_LIBRARY_PATH"
    fi
fi
if [[ $output==1 && -n $MISC_LIB ]]; then
    echo "MISC_LIB        $MISC_LIB"
fi


### ----------- FSL ------------ ####
if [ -n $FSL_DIR ]; then
    export FSLDIR=$FSL_DIR
    export FSL_BIN=$FSL_DIR/bin
    if [ ! -d $FSL_BIN ]; then
        if [ $output==1 ]; then
            echo "WARNING: $FSL_BIN does not exist.";
        fi
    fi
    if [ -e $FSL_DIR/etc/fslconf/fsl.sh ]; then
        source $FSL_DIR/etc/fslconf/fsl.sh
    fi
fi
if [ -n $FSL_BIN ]; then
    PATH=$FSL_BIN:$PATH
fi
if [[ $output==1 && -n $FSL_DIR ]]; then
    echo "FSL_DIR         $FSL_DIR"
fi


### ----------- Freesurfer Bin and Lib Paths  ------------ ####
export PATH=$FSFAST_HOME/bin:$FREESURFER_HOME/bin/noarch:$FREESURFER_HOME/bin:$PATH

## Add path to OS-specific static and dynamic libraries.
if [ -z $LD_LIBRARY_PATH ]; then
    export LD_LIBRARY_PATH=$FREESURFER_HOME/lib/
else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH":"$FREESURFER_HOME/lib/"
fi
if [ -z $DYLD_LIBRARY_PATH ]; then
    export DYLD_LIBRARY_PATH=$FREESURFER_HOME/lib/
else
    export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH":"$FREESURFER_HOME/lib/"
fi

# cause OS to build new bin path cache:
#rehash;  # not needed for bash!


return 0;
####################################################################
