import os
import json

######### Variables #################
# this program will get NAS HDD details and post these details to NODE-RED Server
QNAP_UID = 'schahar'
QNAP_PWD = 'Tuhina@0404'
NODE_RED_ENPOINT_URL = 'http://nodered.sc:1880/nas_hdd_details'
ARRAY_SEPERATOR = '__##__##__'
#####################################

##################### common functions 
def substring_after(s, delim):
    return s.partition(delim)[2]

######################## end functions

class drive:
    def __init__(self, name, totalsize,free,used,free_per):
        self.name = name
        self.totalsize = totalsize
        self.free = free
        self.used = used
        self.free_per = free_per
        
########################################################

    
print('\nGet SID for QNAP')
stream = os.popen('qcli -l user=' + QNAP_UID + ' pw=' + QNAP_PWD)
output = stream.readlines()
# print(output)

# stip command to remove newline character and then convert array output to string 
sid_string = ' '.join(str(x.strip()) for x in output) 

# get sid from above response 
sid_fetch = substring_after(sid_string, "sid is").strip()

if sid_fetch.strip():
   print('\nQNAP SID Found: "' + sid_fetch + '"')
else:
    print("\n------------------------------------------------------------------------------------------------------")
    print("\nError Fetching SID : " + sid_string)
    print("\n------------------------------------------------------------------------------------------------------\n\n\n")
    exit()
    
# Now get the Volume Information 
stream = os.popen('qcli_volume -i sid='+sid_fetch+' displayfield=Alias,Capacity,FreeSize')
output = stream.readlines()
# print(output)

# remove first 3 items from the array since there are only headers
del output[:3]

print('\nWhat is the Type of Command Response: ' + type(output).__name__ + '\n')

# creating list to store all drivers information
lst = []

for x in output:
  row = x.strip().replace(' GB', '') # remove GB substring 
  row = row[::-1] # reverse string 
  list_of_strings = row.split()
  #print(list_of_strings)
  free_size = int(list_of_strings[0][::-1].strip()) # get first element and reverse string
  totalsize = int(list_of_strings[1][::-1].strip()) # get first element and reverse string
  used = totalsize - free_size
  free_per = int(round((float(free_size) / float(totalsize))*100))
  del list_of_strings[:2] #remove first two elements which is total capicity and free availabel size 
  drv_name = (' '.join(str(x.strip()) for x in list_of_strings))[::-1].strip() # append remaining array element and string reverse it and trim it
  lst.append(drive(name=drv_name, totalsize=totalsize,free=free_size, used=used, free_per=free_per )) 
  
  
#Convert object to JSON String 
json_string = json.dumps([ob.__dict__ for ob in lst])
print('\nMessage to Send NODE-RED Below: \n')
print(json_string)
print('\n\n')
print('\n\n')

#Get Uptime
stream = os.popen('uptime')
output = stream.readlines()
output = ' '.join(str(x.strip()) for x in output) 
output = output.split(',')[0] # remove every thing after comma 
output = output.split(' ')
output.pop(0)
output = ' '.join(str(x.strip()) for x in output) 
other_details =  output;

#Get Kernal Name
stream = os.popen('cat /etc/*-release | egrep "PRETTY_NAME" | cut -d = -f 2 | tr -d \'"\' |  xargs')
output = stream.readlines()
output = ' '.join(str(x.strip()) for x in output) 
output = output.split(' ')
output = ' '.join(str(x.strip()) for x in output) 
other_details = other_details + ARRAY_SEPERATOR + output
             
stream = os.popen('curl -X POST ' + ' "'+NODE_RED_ENPOINT_URL+'" -H "Content-Type: application/text" -d \'' + json_string + ARRAY_SEPERATOR + other_details + '\'')

print('\n\n')
print('\n\n')
output = stream.readlines()
print('\n\nResponse from Node-RED:  ' + ' '.join(str(x.strip()) for x in output) )
