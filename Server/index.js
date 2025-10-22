







const express=require('express');
const mongoose=require('mongoose');
const app =express();

app.get('/',(req,res)=>{
    res.send(" hello from node api server using express");
})
 mongoose.connect("mongodb+srv://dwikatlama4_db_user:xiqgYq-jesfob-6zatgo@cluster0.bvlsdmx.mongodb.net/trialCollection?retryWrites=true&w=majority&appName=Cluster0")
 .then(()=>{
    console.log("connected to DB");
    app.listen(3000,()=>{
        console.log('server is running on port 3000');
    });
 }).catch(()=>{
    console.error("Error connecting to DB:");
 });

 app.use(express.json());
 


 