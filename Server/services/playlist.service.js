import PlayList from '../models/playList.model.js';
import mongoose from "mongoose";





export const playlistService={

async createPlayList(data ){
 const newplaylist=new PlayList(data);
 return await newplaylist.save();
  },

 async addVideoToPlayList(playlistId,videoId,){

return await PlayList.findByIdAndUpdate(
    playlistId,
    {$addToSet:{videos:videoId}},
    {new:true},
)
},

async updatePlaylist(playlistId,updateData){ 
    return await PlayList.findByIdAndUpdate(playlistId,updateData,{new:true})
},
async deleteVideoFromPlayList(playlistId,videoId,){
    return await PlayList.findByIdAndUpdate(
        playlistId, 
        {$pull:{videos:videoId}},
        {new:true}
    )
},
async deletePlayList(playlistId){
return await PlayList.findByIdAndDelete(playlistId);
},

async getPlaylistbySupervisor(supervisorId){
    return await PlayList.find({createdBy:supervisorId})
},

async getPlaylistById(playlistId){
return await PlayList.findById(playlistId)
},

async getAllPlaylists(){
    return await PlayList.find();
},
async deleteAllPlaylists(){
    return await PlayList.deleteMany();
},

//  async getPlaylistsNumbers(supervisorId){
//   return await PlayList.countDocuments({createdBy:new mongoose.Types.ObjectId(supervisorId)});
//  },

// Get total number of playlists
async getPlaylistsNumbers(supervisorId = null) {
  const filter = {};

  if (supervisorId && mongoose.Types.ObjectId.isValid(supervisorId)) {
    filter.createdBy = new mongoose.Types.ObjectId(supervisorId);
  }

  return await PlayList.countDocuments(filter);
},

 async publishPlaylist(id , isPub){
       return await PlayList.findByIdAndUpdate(id , {isPublished:isPub},{new:true})
 },

 async getPlaylistsByAge(age){
  return await PlayList.find({isPublished:true,ageGroup:age})

 }
}