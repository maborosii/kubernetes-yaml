import yaml
import os
import json


PATH = "/Users/heheda/Desktop/Coding/kubernetes/prometheus/prometheus/config/"
yaml_file = os.path.join(PATH, "prometheus.yaml")


with open(yaml_file,"r") as file:
    dict_data = yaml.load(file)

json_data = json.dumps(dict_data)
print(json_data)