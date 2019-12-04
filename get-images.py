# coding=utf-8

# 说明，使用之前需要先安装一下PyYaml
# sudo pip install PyYaml

yaml_path = 'values.yaml'

import yaml

def get_target_segment(j, target):
    target_list = []
    for key, value in j.items():
        if isinstance(value, dict):
            if key == 'image':
                target_list.append(value)
            else:
                target_list += get_target_segment(value, target)
        else:
            continue
    return target_list


yaml_file = open(yaml_path,'r')
cont = yaml_file.read()
values = yaml.load(cont, Loader=yaml.FullLoader)


images = get_target_segment(values, 'image')
content = ""
for image in images:
    image_name = "%s:%s\n" % (image['repository'], image['tag'])
    content += image_name

with open("/tmp/harbor-images.txt", "a") as f:
    f.write(content)




