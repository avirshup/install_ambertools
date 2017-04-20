#!/bin/sh

at_version=17
amberfolder='amber'$at_version
channel='http://ambermd.org/downloads/ambertools/conda/'
pyver=2
MINICONDA_VERSION=4.3.11

set -e


print_help() {
    echo "`basename $0` [options]"
    echo ""
    echo "Options"
    echo "-------"
    echo "    -h, --help    Print this message and exit"
    echo "    -v VERSION, --version VERSION"
    echo "                  What version of Python do you want installed? Input"
    echo "                  can be either 2 (default) or 3. Note, Phenix support"
    echo "                  requires Python 2"
    echo "    -p PREFIX, --prefix PREFIX"
    exit 1
}

function message_source_amber(){
    amberhome=`$prefix/$amberfolder/bin/python -c "import sys; print(sys.prefix)"`
    echo ""
    echo "----------------------------------------------------------------------"
    echo "Environment resource files are provided to set the proper environment"
    echo "variables to use AMBER and AmberTools."
    echo ""
    echo "If you use a Bourne shell (e.g., bash, sh, zsh, etc.), source the"
    echo "$amberhome/amber.sh file in your shell. Consider adding the line"
    echo "  source $amberhome/amber.sh"
    echo "to your startup file (e.g., ~/.bashrc)"
    echo ""
    echo "If you use a C shell (e.g., csh, tcsh), source the"
    echo "$amberhome/amber.csh file in your shell. Consider adding the line"
    echo "  source $amberhome/amber.csh"
    echo "to your startup file (e.g., ~/.cshrc)"
    echo ""
}


# Process command-line
while [ $# -ge 1 ]; do
    case "$1" in
        -h|--help)
            print_help
            ;;
        -v|--version)
            shift;
            if [ $# -lt 1 ]; then
                print_help
            fi
            pyver=$1
            ;;
        -p|--prefix)
            shift;
            if [ $# -lt 1 ]; then
                print_help
            fi
            prefix=$1
            ;;
        *)
            echo "Unsupported argument: $1"
            print_help
            ;;
    esac
    shift
done

if [ -d $prefix/$amberfolder ]; then
    echo "ERROR: $prefix/$amberfolder already exists. Please change your prefix."
    exit 1
fi

# should work for both osx and linux
osname=`python -c 'import sys; print(sys.platform)'`
if [ $osname = "darwin" ]; then
    wget https://repo.continuum.io/miniconda/Miniconda${pyver}-${MINICONDA_VERSION}-MacOSX-x86_64.sh -O miniconda.sh;
else
    wget https://repo.continuum.io/miniconda/Miniconda${pyver}-${MINICONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh;
fi

echo "Install Miniconda and AmberTools to $prefix/$amberfolder"
echo ""

bash miniconda.sh -b -p $prefix/$amberfolder

export PATH=$prefix/$amberfolder/bin:$PATH
conda update --all -y
conda install --yes conda-build jinja2 pip cython numpy nomkl pytest
conda install --yes scipy
conda install --yes ipython notebook
$prefix/$amberfolder/bin/pip install pip --upgrade
$prefix/$amberfolder/bin/pip install matplotlib # avoid qt
conda install --yes ipywidgets

if [ $pyver = 2 ]; then
    conda install --yes nglview -c bioconda
else
    # no (conda) nglview for python 3.6 yet
    pip install nglview
fi

# TODO: change to ambermd channel
conda install --yes ambertools=$at_version -c $channel
conda clean --all --yes

# alias
cwd=`pwd`
cd $prefix/$amberfolder/bin
ln -sf python amber.python || error "Linking Amber's Miniconda Python"
ln -sf conda amber.conda || error "Linking Amber's Miniconda conda"
ln -sf ipython amber.ipython || error "Linking Amber's Miniconda ipython"
ln -sf jupyter amber.jupyter || error "Linking Amber's Miniconda jupyter"
ln -sf pip amber.pip || error "Linking Amber's Miniconda pip"
cd $cwd

# Write resource files
amberhome=`$prefix/$amberfolder/bin/python -c "import sys; print(sys.prefix)"`
cat > $prefix/$amberfolder/amber.sh << EOF
export AMBERHOME="$amberhome"
export PATH="\${AMBERHOME}/bin:\${PATH}"
EOF

cat > $prefix/$amberfolder/amber.csh << EOF
setenv AMBERHOME "$amberhome"
setenv PATH "\${AMBERHOME}/bin:\${PATH}"
EOF

message_source_amber
