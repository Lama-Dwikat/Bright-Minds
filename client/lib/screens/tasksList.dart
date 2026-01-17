// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import "package:bright_minds/theme/colors.dart";



// class Task{
//   String text;
//   bool done;
//   Task({required this.text,  this.done=false});
// }

// class TasksList extends StatefulWidget{
//   const TasksList({super.key});

//   @override
//   State <TasksList> createState() => _TasksListScreen();
// }

// class _TasksListScreen extends State<TasksList>{
//   List <Task> tasks=[
//    Task(text:"rate lina new story"),
//    Task(text:"check mousa new drawing"),
//     Task(text:'add new story competition about honest'),
//   ];

//    final List<Map<String,dynamic>> weekdays=[
//       {"day":"Sun","key":1},
//       {"day":"Mon","key":2},
//       {"day":"Tue","key":3},
//       {"day":"Wed","key":4},
//       {"day":"Thu","key":5},
//       {"day":"Fri","key":7},
//       {"day":"Sat","key":8}
//     ];
  

//   double get progress =>
//   tasks.isEmpty ? 0 : tasks.where((t)=>t.done).length/tasks.length;
     
   

//   @override
//   Widget build(BuildContext context) {
//     final today = DateTime.now();
//     final formattedDate = DateFormat("d MMM yyyy").format(today);
//        return SizedBox(
//     height: 400,
//     child:Center( // give fixed height so Stack can render
// child: Stack(

//   children: [
//     // 1. The background or main layout
//       Container(decoration:BoxDecoration(
//       color:Colors.transparent,
//        )),
        
//         Column(
//            crossAxisAlignment: CrossAxisAlignment.start,
//         children:[
//       Container(
//         decoration:BoxDecoration(
//                color:AppColors.bgBlushRoseDark,
//         border:Border(
//        top: BorderSide(color: Colors.black, width: 2),
//       left: BorderSide(color: Colors.black, width: 2),
//       right: BorderSide(color: Colors.black, width: 2),
//         ),),
   
//        padding: EdgeInsets.all(8), // optional, for spacing
//         child:Text('$formattedDate')
//       ),
//     // 2. Tasks container (the “cobayisner”)
//     Positioned(
//       left: 60, // position near the kid’s hand
//       top: 137.5,
//       child: Container(
//         width: 300,
//         height: 300,
//         padding: EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: AppColors.bgBlushRoseDark,
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Column(
//           children: [
//             // Weekdays
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: weekdays.map((entry) {
//                 final day = entry['day']!;
//                 final dayNum = entry['key']!;
//                 final bool isToday = today.weekday == dayNum;
//                 return Container(
//                   padding: EdgeInsets.all(6),
//                   decoration: isToday
//                       ? BoxDecoration(
//                           color: Color(0xffbfa8ff),
//                           shape: BoxShape.circle,
//                         )
//                       : null,
//                   child: Text(
//                     "$day",
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: isToday ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),

//             SizedBox(height: 10),

//             // Tasks list
//             Expanded(
//               child: ListView.builder(
//                 itemCount: tasks.length,
//                 itemBuilder: (context, index) {
//                   final task = tasks[index];
//                   return Container(
//                     margin: EdgeInsets.symmetric(vertical: 4),
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(task.text),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),

//         ],
//         ),


//     // 2. Kid image

//     //     Positioned(
//     //   left:-15.5, // adjust X position
//     //   top: 15.75, // adjust Y position
//     //   child: Image.asset(
//     //     "assets/images/tasks3.png",
//     //     width: 150,
//     //     height: 250,
//     //   ),
//     // ),

//   ],
// ),
//        ),
//        );
   
// }

// }




