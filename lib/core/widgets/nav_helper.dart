import 'package:flutter/material.dart';


extension NavHelper on BuildContext {
  to(page) {
    Navigator.push(this, MaterialPageRoute(builder: (_) => page,));
    debugPrint("****** Go to $page");
  }

  Future<bool?> toCallBack(page) async{
    debugPrint("****** Go to $page");
   return await Navigator.push<bool>(this, MaterialPageRoute(builder: (_) => page,),);
  }

  rTo(page) {
    Navigator.pushReplacement(this, MaterialPageRoute(builder: (_) => page));
    debugPrint("****** Go to $page");
  }

  rAndRemoveUntilTo(page) {
    Navigator.pushAndRemoveUntil(
      this,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
    debugPrint("****** Go to $page");
  }

  pop() {
    Navigator.of(this).pop();
  }
}
