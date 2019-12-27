from flask import Flask
from flask import render_template
from flask import request

import os
import json
import datetime
import re
import threading
import traceback
import uuid
import os
from skimage import io
import numpy as np
import pydicom
import xml.etree.ElementTree as ET
import shutil
from io import BytesIO

import cProfile

from CFAImageGenerator import CFAImageGenerator
from ContinousImage3D import ContinousImage3D
from CLine import CLine
from Vector3D import Vector3D

import werkzeug.formparser
def default_stream_factory(total_content_length, filename, content_type, content_length=None):
    """The stream factory that is used per default."""
    # if total_content_length > 1024 * 500:
    #    return TemporaryFile('wb+')
    # return BytesIO()
    return BytesIO()
werkzeug.formparser.default_stream_factory = default_stream_factory
io.use_plugin("tifffile")
# Initialize Flask
app = Flask(__name__)

# Define the index route
@app.route("/")
def index():
    return render_template('index.html')

@app.route("/cfa",methods=["post"])
def cfa():
    try:
        #prepare a workspace
        id = uuid.uuid1()
        path = "./tmp/" + str(id)
        os.makedirs(path)

        #save all files
        dcm_path = os.path.join(path,"img.dcm")
        request.files["dcm"].save(dcm_path)
        dcm_data = pydicom.dcmread(dcm_path)

        i = BytesIO(request.files["tif"].stream.read())
        img_data = io.imread(i)

        mask_data = None
        if request.files["mask"].content_length > 0:
            mask_i = BytesIO(request.files["mask"].stream.read())
            mask_data = io.imread(mask_i)

        cline_path = os.path.join(path,"cline.xml")
        request.files["cline"].save(cline_path)
        tree = ET.parse(cline_path)
        root = tree.getroot()
        #we ignore 4. 5. and 6. dimension and convert the xml data to float
        cline_bare = [[float(y) for y in x.text.split()][:3] for x in root.iter() if x.tag == "pos"]
                
        #get all params from form
        sample_strategy = request.form["sample_strategy"]
        sample_frequency = float(request.form["sample_frequency"])
        circle_delta = float(request.form["circle_delta"])
        cline_step_distance = float(request.form["cline_step_distance"])
        max_radius = float(request.form["max_radius"])
        left = request.form["left"]
        right = request.form["right"]
        ctx = None
        ctx_side = None
        ctx_samples = None
        if "context" in request.form.keys():
            ctx_side = request.form["ctx_side"]
            ctx_samples = int(request.form["ctx_samples"])
            ctx = {"side" : ctx_side, "samples" : ctx_samples}
        sta = None
        stability_w = None
        stability_percentile = None
        if "stability" in request.form.keys():
            stability_w = int(request.form["stability_w"])
            stability_percentile = float(request.form["stability_percentile"])
            sta = {"w" : stability_w, "percentile" : stability_percentile}
        
        #if mask_data is given, we want to apply it as a filter
        if mask_data:
            img_data = np.multiply(img_data,mask_data)
        
        #we need to read some data from the dicom file
        #this is the x,y distance in mm
        pixel_spacing = [float(x) for x in dcm_data.PixelSpacing]
        slice_spacing = float(dcm_data.SpacingBetweenSlices)
        #offset of the first (upper left) voxel
        location = [float(x) for x in dcm_data.ImagePositionPatient]
        location_v = Vector3D(location[0],location[1],location[2])

        cline = [Vector3D(x[0],x[1],x[2]) for x in cline_bare]
        center_line = CLine(cline)
        cimg = ContinousImage3D(img_data,x_scale=pixel_spacing[0],y_scale=pixel_spacing[1],z_scale=slice_spacing,location=location_v)

        cfa = CFAImageGenerator(cimg,center_line,
                      sample_strategy=sample_strategy,
                      sample_frequency=sample_frequency,
                      circle_delta=circle_delta,
                      max_radius=max_radius,
                      cline_step_distance=cline_step_distance,
                      left=left,
                      right=right,
                      context=ctx,
                      stability=sta)

        #calculate the image
        cfa.calculate_all()
        cfa.render_image()
        img_path = "./static/results/"+str(id)+".png"
        cfa.plot(img_path,dpi=int(request.form["dpi"]))

        return render_template('cfa.html', uuid=str(id),left=left,right=right,sample_frequency=sample_frequency,sample_strategy=sample_strategy,
            max_radius=max_radius,circle_delta=circle_delta,cline_step_distance=cline_step_distance,cline_length=center_line.length,
            img_res=cimg.shape,ctx_side=ctx_side, ctx_samples=ctx_samples, stability_w=stability_w,stability_percentile=stability_percentile)
    except Exception as e:
        print(e)
        log_error(e)
        return render_template('error.html', message=str(e) + str(traceback.format_exc()))


error_location = "./error.log"
data = dict()

def log_error(text):
    with open(error_location, 'a+') as errorfile:
        errorfile.write(str(datetime.datetime.now()) + ": " + str(text))
    
# Run Flask if the __name__ variable is equal to __main__
if __name__ == "__main__":
    #dont forget to set host and port according to your needs
    app.config['MAX_CONTENT_LENGTH'] = 4* 1024*1024*1024#4GB
    app.config['UPLOAD_FOLDER'] = "./"
    app.run(port=8585,host="0.0.0.0")
