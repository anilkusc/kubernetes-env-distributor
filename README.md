# kubernetes-env-distributor
this perl script take environments from secret file and apply it to all yaml files in the same directory.
It creates a new folder named newdir and new yaml files deploy into that folder.
First argument of script is for specify secret file.If you do not give any argument while running it takes secret file "secrets.yaml" as default.
You should use " on strings on your yaml files for use this script.
# TODOS:
#TODO:reformat it for kubernetes yaml <br>
#TODO:include(if there is value in include list only append it) and exclude list for yaml files <br>
#TODO:include and exclude list for stringData in secrets.yaml <br>
#TODO:more options. <br>
