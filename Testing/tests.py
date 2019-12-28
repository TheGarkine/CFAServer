#with this script you can automatically create tons of requests
import requests
import time
import os
import urllib
import re
import math
result_dir = "results"
os.makedirs(result_dir)
counter = 0
url = "http://localhost:8585"


#set this variable to the datapath of your directories
data_path = "/home/raphael/Documents/avmedbild-data/"

sample_strategies = [
    ("const_num",16)]

circle_deltas = [.1]
cline_step_distances = [.1]
max_radii = [25]
agg_functions = ["MIP","MINIP"]
agg_function_pairs = list()
for l in range(len(agg_functions)):
    for r in range(len(agg_functions)):
        if(l >= r):
            continue
        agg_function_pairs.append([agg_functions[l],agg_functions[r]])
dpis = [640]
cline_paths = ["LAD","LCX","RCA"]
dirs = [
    ("cta_0","cardiac_0"),
    ("cta_1","cardiac_1"),
    ("cta_2","cardiac_2"),
    ("cta_3","cardiac_3"),
]
datasets = list()
for d,n in dirs:
    for cp in cline_paths:
        datasets.append({
            "dir": d,
            "name": n,
            "cline": cp
        })

contexts = [None,{"context":1,"ctx_side":"posterior","ctx_samples":7}]
stabilities = [None,{"stability":1, "stability_w":3,"stability_percentile":95}]

use_masks = [False]
for ss,sf in sample_strategies:
    for cd in circle_deltas:
        for csd in cline_step_distances:
            for mr in max_radii:
                for l , r in agg_function_pairs:
                    for d in dpis:
                        for s in datasets:
                            for um in use_masks:
                                for ctx in contexts:
                                    for stab in stabilities:
                                        print("Test #" + str(counter))
                                        path = os.path.join(result_dir,str(counter))
                                        os.makedirs(path)
                                        config = {
                                                "sample_strategy":ss,
                                                "sample_frequency":sf,
                                                "circle_delta":cd,
                                                "cline_step_distance":csd,
                                                "max_radius":mr,
                                                "left":l,
                                                "right":r,
                                                "dpi":d,
                                        }

                                        if ctx:
                                            config.update(ctx)
                                        else:
                                            config["context"] : None
                                        
                                        if stab:
                                            config.update(stab)
                                        else:
                                            config["stability"] : None
                                        config["dcm_file"] = data_path + s["dir"] + "/" + s["name"] + ".dcm"
                                        config["tif_file"] = data_path + s["dir"] + "/" + s["name"] + ".tif"
                                        config["cline_file"] = data_path + s["dir"] + "/cline_" + s["cline"] + ".xml"
                                        files = {
                                            "dcm":open(config["dcm_file"],"rb"),
                                            "tif":open(config["tif_file"],"rb"),
                                            "cline":open(config["cline_file"],"rb"),
                                        }
                                        if um:
                                            config["mask_file"] = data_path + s["dir"] + "heart_isolationmask.tif"
                                            files["mask"] = open(config["mask_file"],"rb")
                                        else:
                                            config["mask_file"] = None
                                            files["mask"] = ""
                                        
                                        with open(os.path.join(path,"config.txt"),"w") as f:
                                            f.write(str(config))
                    

                                        res = requests.post(url+"/cfa",data=config,files=files)
                                        with open(os.path.join(path,"page.html"),"w") as f:
                                            f.write(res.text)
                                        src = re.search(r'src="(.*)"',res.text)
                                        if src:
                                            src = src.groups()[0]
                                            urllib.request.urlretrieve(url+src,os.path.join(path,"img.png"))
                                        else:
                                            print("Error with this test, see the html file for more info.")
                                        counter += 1