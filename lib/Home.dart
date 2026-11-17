import 'package:flutter/material.dart';
class home extends StatelessWidget {
  const home({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
       appBar: AppBar(
         title: Text("My favourite places",style: TextStyle(
       fontSize: 25,fontWeight: FontWeight.bold,color: Colors.green),),
         centerTitle: true,
         backgroundColor: Colors.deepPurple,
       ),



    );
  }
}
