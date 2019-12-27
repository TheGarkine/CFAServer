import requests
import time

path = "/home/raphael/Documents/avmedbild-data/cta_0/"

form_data = {
        "sample_strategy":"const_num",
        "sample_frequency":64,
        "circle_delta":.5,
        "cline_step_distance":.5,
        "max_radius":50,
        "left":"MIP",
        "right":"MINIP",
        "dpi":320
}

files = {
    "dcm":open(path+"cardiac_0.dcm","rb"),
    "tif":open(path+"cardiac_0.tif","rb"),
    "cline":open(path+"cline_LAD.xml","rb"),
    "mask":open(path+"heart_isolationmask.tif","rb")
}

then = time.time()
r = requests.post("http://localhost:8585/cfa",data=form_data,files=files)
print(r.text)
print(time.time() - then)