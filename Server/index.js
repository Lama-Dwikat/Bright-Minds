const express = require ('express')
const mongoose = require ('mongoose');
const app = express()





app.get('/', (req,res) => {
    res.send("hello from node api server using express");
});

mongoose.connect("mongodb+srv://fatima2004nasser_db_user:ddLRmTvoPt6mmpRJ@cluster.ginozpp.mongodb.net/Node-API?retryWrites=true&w=majority&appName=Cluster")
.then(() => {
    console.log("connected to DB");
    app.listen(3000,() => {
     console.log('server is running on port 3000');
     });
})
.catch((err) => {
    console.error("Error connecting to DB:", err);
});
