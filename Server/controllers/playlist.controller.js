import { playlistService } from "../services/playlist.service.js";


export const playlistController={





async createPlayList(req,res ){

  try{
    const playlist= await playlistService.createPlayList(req.body);
    res.status(200).json(playlist);

    }catch(error){
            res.status(500).json({ error: error.message });

    }
  },

 async addVideoToPlayList(req,res){

  try{ 
    const {videoId} = req.body
    
    const playlist= await playlistService.addVideoToPlayList(req.params.id,videoId)
    if(!playlist)
        return res.status(400).json({message:"playlsit not found"});
    return res.status(200).json(playlist)
    }catch(error){
            res.status(500).json({ error: error.message });

    }
},

async updatePlaylist(req,res){ 
  try{
 const playlist=await  playlistService.updatePlaylist(req.params.id,req.body)
    if(!playlist)
        return res.status(400).json({message:"playlsit not found"});
    return res.status(200).json(playlist)
    }catch(error){
            res.status(500).json({ error: error.message });

    }
},
async deleteVideoFromPlayList(req, res) {
  try {
    const { videoId } = req.body;
    const playlist = await playlistService.deleteVideoFromPlayList(req.params.id, videoId);
    if (!playlist) {
      return res.status(400).json({ message: "playlist not found" });
    }
    return res.status(200).json(playlist);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
},

async deletePlayList(req,res){
try{
 const playlist= await playlistService.deletePlayList(req.params.id)
    if(!playlist)
        return res.status(400).json({message:"playlsit not found"});
    return res.status(200).json(playlist)
    }catch(error){
            res.status(500).json({ error: error.message });

    }},

async getPlaylistbySupervisor(req,res){

  try{

const playlist=await  playlistService.getPlaylistbySupervisor(req.params.id)
    if(!playlist)
        return res.status(400).json({message:"supervisor not found"});
    return res.status(200).json(playlist)
    }catch(error){
            res.status(500).json({ error: error.message });

    }},

async getPlaylistById(req,res){

  try{
const playlist=await playlistService.getPlaylistById(req.params.id)
    if(!playlist)
        return res.status(400).json({message:"playlsit not found"});
    return res.status(200).json(playlist)

    }catch(error){
            res.status(500).json({ error: error.message });

    }},

async getAllPlaylists(req,res){
  try{
const playlist= await playlistService.getAllPlaylists()
    if(!playlist)
        return res.status(400).json({message:"failed to get all playlists"});
    return res.status(200).json(playlist)

    }catch(error){
            res.status(500).json({ error: error.message });

    }},

async deleteAllPlaylists(req,res){

  try{

 const playlist= await playlistService.deleteAllPlaylists()
    if(!playlist)
        return res.status(400).json({message:"failed to delete playlists"});
    return res.status(200).json(playlist)

    }catch(error){
            res.status(500).json({ error: error.message });

    }
}








}