FROM nvidia/cuda:9.0-cudnn7-devel-centos7
MAINTAINER Alex Himmel "ahimmel@fnal.gov"

RUN yum -y upgrade
RUN yum -y install epel-release yum-plugin-priorities

# osg repo
RUN yum -y install http://repo.opensciencegrid.org/osg/3.4/osg-3.4-el7-release-latest.rpm

# pegasus repo
RUN echo -e "# Pegasus\n[Pegasus]\nname=Pegasus\nbaseurl=http://download.pegasus.isi.edu/wms/download/rhel/7/\$basearch/\ngpgcheck=0\nenabled=1\npriority=50" >/etc/yum.repos.d/pegasus.repo

# well rounded basic system to support a wide range of user jobs
RUN yum -y groups mark convert
RUN yum -y grouplist
RUN yum -y groupinstall "Compatibility Libraries" \
                    "Development Tools" \
                    "Scientific Support"


RUN yum -y install \
	redhat-lsb \
	bc \
	binutils \
	binutils-devel \
	coreutils \
	curl \
	fontconfig \
	gcc \
	gcc-c++ \
	gcc-gfortran \
	git \
	glew-devel \
	glib2-devel \
	glib-devel \
	graphviz \
	gsl-devel \
        gtk3 \
	java-1.8.0-openjdk \
	java-1.8.0-openjdk-devel \
        libcurl \
	libgfortran \
	libGLU \
	libgomp \
	libicu \
	libquadmath \
	libtool \
	libtool-ltdl \
	libtool-ltdl-devel \
	libX11-devel \
	libXaw-devel \
	libXext-devel \
	libXft-devel \
	libxml2 \
	libxml2-devel \
	libXmu-devel \
	libXpm \
	libXpm-devel \
	libXt \
	mesa-libGL-devel \
	openssh \
	openssh-server \
	openssl \
        openssl-devel \
	osg-wn-client \
	p7zip \
	p7zip-plugins \
        pkg-config \
        python \
        python3 \
        python3-markdown \
        python3-pip \
        python3-requests \
        python3-tk \
        python3-yaml \
        python-dev \
        python-markdown \
        python-numpy \
        python-pip \
        python-requests \
        python-yaml \	
	redhat-lsb-core \
	rsync \
        stashcache-client \
	subversion \
	tcl-devel \
	tcsh \
	time \
	tk-devel \
	wget \
	which

# osg
RUN yum -y install osg-ca-certs osg-wn-client
RUN rm -f /etc/grid-security/certificates/*.r0

# htcondor - include so we can chirp
RUN yum -y install condor

# pegasus
RUN yum -y install pegasus

# Cleaning caches to reduce size of image
RUN yum clean all

# required directories
RUN for MNTPOINT in \
    /cvmfs \
    /hadoop \
    /hdfs \
    /lizard \
    /mnt/hadoop \
    /mnt/hdfs \
    /xenon \
    /spt \
    /stash2 \
    /srv \
    /scratch \
    /data \
    /project \
  ; do \
    mkdir -p $MNTPOINT ; \
  done

# make sure we have a way to bind host provided libraries
# see https://github.com/singularityware/singularity/issues/611
RUN mkdir -p /host-libs /etc/OpenCL/vendors


# Create an empty location for nvidia executables
RUN for NVBIN in \
    nvidia-smi \
    nvidia-debugdump \
    nvidia-persistenced \
    nvidia-cuda-mps-control \
    nvidia-cuda-mps-server \
  ; do \
    touch /usr/bin/$NVBIN ; \
  done

##############################################
# Install TensorFlow, Keras, etc. with Python
   
RUN echo "/usr/local/cuda/lib64/" >/etc/ld.so.conf.d/cuda.conf
RUN echo "/usr/local/cuda/extras/CUPTI/lib64/" >>/etc/ld.so.conf.d/cuda.conf

# only support python3

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade setuptools

RUN python3 -m pip --no-cache-dir install \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        Pillow \
        scipy \
        sklearn \
        && \
    python3 -m ipykernel.kernelspec

# Install TensorFlow GPU version.
RUN echo "Install tensorflow and tensorflow_addons"
RUN python3 -m pip install --upgrade tensorflow==1.12 keras
#RUN python3 -m pip install --upgrade tensorflow_addons==0.8.3

#############################

# make sure we have a way to bind OpenCL directory
RUN mkdir -p /etc/OpenCL/vendors 

# CA certs
RUN mkdir -p /etc/grid-security && \
    cd /etc/grid-security && \
    wget -nv https://download.pegasus.isi.edu/containers/certificates.tar.gz && \
    tar xzf certificates.tar.gz && \
    rm -f certificates.tar.gz

# stashcp
RUN python3 -m pip install stashcp

#################################
# Manually add Singularity files

RUN git clone https://github.com/jthiltges/singularity-environment.git /usr/singularity-environment/
RUN cp -r /usr/singularity-environment/{environment,.exec,.run,.shell,singularity,.singularity.d,.test} /
RUN mkdir /.singularity.d/libs

#################################
# According to: https://docs-dev.nersc.gov/cgpu/software/#shifter-with-cuda
RUN echo "export PATH and LD_LIBRARY_PATH"
ENTRYPOINT export PATH=/opt/shifter/bin:${PATH} && export LD_LIBRARY_PATH=/opt/shifter/lib:${LD_LIBRARY_PATH}

############
# Finish up

# build info
RUN echo "Timestamp:" `date --utc` | tee /image-build-info.txt


