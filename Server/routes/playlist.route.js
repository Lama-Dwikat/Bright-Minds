import { playlistController } from "../controllers/playlist.controller.js";
import express, { Router } from "express"

export const playlistRouter= express.Router();

playlistRouter.post('/playlists/createPlaylist',playlistController.createPlayList);
playlistRouter.put('/playlists/addVideo/:id',playlistController.addVideoToPlayList);
playlistRouter.put('/playlists/updatePlaylist/:id',playlistController.updatePlaylist);
playlistRouter.put('/playlists/deleteVideo/:id',playlistController.deleteVideoFromPlayList);
playlistRouter.put('/playlists/updatePlaylist/:id',playlistController.updatePlaylist);
playlistRouter.get('/playlists/getPlaylist/:id',playlistController.getPlaylistById);
playlistRouter.get('/playlists/getlAllPlaylists',playlistController.getAllPlaylists);
playlistRouter.get('/playlists/getPlaylistBySupervisor/:id',playlistController.getPlaylistbySupervisor);
playlistRouter.delete('/playlists/deletePlaylist/:id',playlistController.deletePlayList);
playlistRouter.delete('/playlists/deleteAllPlaylists/',playlistController.deleteAllPlaylists);






