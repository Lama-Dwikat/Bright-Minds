import mongoose from 'mongoose';

 const UserSchema=new mongoose.Schema({
    firstName:{
    type:String,
    required:true
    },
    lastName:{
    type:String,
    required:true
},
userName:{
    type:String,
    required:true,
    unique:true,
    minlength:3,
    maxlength:30
},
 password:{
    type:String,
    required:true,
    minlength:8,
    maxlength:64

},
role:{
    type:String,
    enum:['child','admin','supervisor',  'parent'],
},
dateOfBirth:{
    type:Date,
    required:true,
 },
 ageGroup:{
    type:String,
    enum:['5-8','9-12'],
 },
 cv:{
type:String,
 },
 cvStatus:{
    type:String,
    enum:['pending','approved','rejected'],
    default:'pending'
 },
 profileImage:{
    type:String,
 },
 email:{
   type:String,
   match:/^[a-zA-Z0-9._%+-]+@gmail\.com$/
 }

  },{timestamps:true} );

  export const userModel=mongoose.model('User',UserSchema);
  //module.exports = userModel;


  