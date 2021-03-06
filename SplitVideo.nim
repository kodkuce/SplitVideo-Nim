import os
import osproc
import streams
import strutils


#Terminate if wrong input
if paramCount()<2:
  echo "Need 2 arguments, filename and size"
  quit(0)
  

if not fileExists(paramStr(1)):
  echo "File not found, do ls or check what you writed"
  quit(0)


try:
  discard parseInt(paramStr(2))
except ValueError:
  echo "Must supply size in number"
  quit(0)


#Check if valid file for ffmpeg
let pr = startProcess("ffprobe","",  ["-i", paramStr(1)]  ,nil,{poStdErrToStdOut, poUsePath})
if pr.outputStream().readAll().contains("Invalid data found when processing input"):
  echo "Input file is not a video"
  pr.close()
  quit(0)
pr.close()



#Exec ffprobe to get exact duration of video
var getDurationArgs : array[8,string] = ["-i", paramStr(1) , "-show_entries", "format=duration", "-v", "quiet", "-of", "default=noprint_wrappers=1:nokey=1"]
let wholeVideoDuration : float = startProcess("ffprobe","",getDurationArgs,nil,{poStdErrToStdOut,poUsePath}).outputStream().readAll().strip().parseFloat()

var 
  atmSeek:float =0
  atmChunk:int =0
  chunkLimit:int =0
  (dir,name,ext)= splitFile(paramStr(1))

echo "Will now start spliting ", name,ext, " that is ", wholeVideoDuration, "s long, in chunks of ", paramStr(2), " size!"


while atmSeek<=wholeVideoDuration-1:

  let n = name & $atmChunk & ext
  echo "Doing split ", n
  
  #Split video
  let splitArgs : array[8,string] = ["-y","-i", name & ext, "-ss", $atmSeek, "-fs", $paramStr(2), n]
  discard startProcess("ffmpeg","", splitArgs , nil, {poStdErrToStdOut,poUsePath}).outputStream.readAll();
 
  
  #Read duration of splited part to know where to continue next one
  getDurationArgs[1]= name & $atmChunk & ext
  let durationOfCreatedFile = startProcess("ffprobe","",getDurationArgs,nil,{poStdErrToStdOut,poUsePath}).outputStream().readAll().strip().parseFloat()
  atmSeek = atmSeek + durationOfCreatedFile

  #Go next chunk
  atmChunk= atmChunk+1
  chunkLimit= chunkLimit+1
  if(chunkLimit>100):
      quit(0)


echo "Finished"
quit(0)








