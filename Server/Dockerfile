FROM python:3.7-alpine3.9
LABEL maintainer="Raphael Krauthann <krauthannra64754@th-nuernberg.com>"

RUN mkdir /server
RUN mkdir /server/static
RUN mkdir /server/static/results
WORKDIR /server

RUN apk update
RUN apk upgrade
RUN apk add --no-cache musl-dev gcc lapack-dev openblas freetype-dev gfortran zlib alpine-sdk build-base jpeg-dev libstdc++ lapack

#general requirements
RUN pip3 install setuptools Cython
#generally used libraries
RUN pip3 install flask request pydicom numpy pillow matplotlib
#dependencies for scipy
RUN pip3 install networkx imageio decorator PyWavelets
#manually install an older version of scipy
RUN mkdir scipy && cd scipy && \
    wget https://github.com/scipy/scipy/releases/download/v1.3.2/scipy-1.3.2.tar.gz && \
    tar -xvf scipy-1.3.2.tar.gz && \
    cd scipy-1.3.2 && \
    python3 -m pip --no-cache-dir install .
#RUN pip3 install scipy
RUN pip3 install --no-binary scipy scikit-image

ADD *.py /server/
ADD *.pyx /server/
ADD templates /server/templates
ADD static /server/static

RUN python3 setup.py build_ext --inplace

CMD ["python3", "/server/app.py"]
