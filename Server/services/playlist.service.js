import PlayList from '../models/playList.model.js';




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
    return await findByIdAndUpdate(playlistId,updateData,{new:true})

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
}


}