import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class Task{
  String text;
  bool done;
  Task({required this.text,  this.done=false});
}

class TasksList extends StatefulWidget{
  const TasksList({super.key});

  @override
  State <TasksList> createState() => _TasksListScreen();
}

class _TasksListScreen extends State<TasksList>{
  List <Task> tasks=[
   Task(text:"rate lina new story"),
   Task(text:"check mousa new drawing"),
    Task(text:'add new story competition about honest'),
  ];
  
double get progress =>
tasks.isEmpty ? 0 : tasks.where((t)=>t.done).length/tasks.length;


  @override
  Widget build(BuildContext context) {
    return Scaffold(



    );


}

}

//   // Clear, standard weekday labels in order Sunday -> Saturday
// final List<Map<String, dynamic>> weekdayHeader = [
//   {'label': 'Sun', 'wd': 7},
//   {'label': 'Mon', 'wd': 1},
//   {'label': 'Tue', 'wd': 2},
//   {'label': 'Wed', 'wd': 3},
//   {'label': 'Thu', 'wd': 4},
//   {'label': 'Fri', 'wd': 5},
//   {'label': 'Sat', 'wd': 6},
// ];


//   @override
//   Widget build(BuildContext context) {
//     final today = DateTime.now();
//     final formattedDate = DateFormat("d MMM yyyy").format(today);

//     return Scaffold(
//       backgroundColor: const Color(0xfff6f4ff),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // DATE BOX (SMALL) - left aligned
//               Row(
//                 children: [
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: const Color(0xffbfa8ff),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       formattedDate,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               // BIG CONNECTED RECTANGLE
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         blurRadius: 15,
//                         offset: const Offset(0, 5),
//                         color: Colors.black.withOpacity(0.07),
//                       )
//                     ],
//                   ),

//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // WEEKDAY HEADER — single correct circle on the current weekday
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: weekdayHeader.map((entry) {
//                           final label = entry['label']!;
//                           final wdNum = entry['wd']!;
//                           final bool isToday = today.weekday == wdNum;

//                           return Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: isToday
//                                 ? BoxDecoration(
//                                     color: const Color(0xffbfa8ff),
//                                     shape: BoxShape.circle,
//                                   )
//                                 : null,
//                             child: Text(
//                               label,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: isToday ? Colors.white : Colors.black87,
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),

//                       const SizedBox(height: 20),

//                       const Text(
//                         "Today's Tasks",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       // TASK LIST
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: tasks.length,
//                           itemBuilder: (context, index) {
//                             final task = tasks[index];
//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 10),
//                               child: Row(
//                                 children: [
//                                   Checkbox(
//                                     value: task.done,
//                                     onChanged: (v) {
//                                       setState(() => task.done = v ?? false);
//                                     },
//                                   ),
//                                   Expanded(
//                                     child: Text(
//                                       task.text,
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         decoration: task.done
//                                             ? TextDecoration.lineThrough
//                                             : null,
//                                         color: task.done ? Colors.grey : Colors.black,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // PROGRESS BAR
//               Column(
//                 children: [
//                   LinearProgressIndicator(
//                     value: progress,
//                     minHeight: 12,
//                     backgroundColor: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(20),
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       progress == 1 ? Colors.green : Colors.deepPurple,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "${(progress * 100).toStringAsFixed(0)}% completed",
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   )
//                 ],
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class Task {
//   String text;
//   bool done;
//   Task({required this.text, this.done = false});
// }


