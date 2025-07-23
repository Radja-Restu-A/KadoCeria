import 'package:flutter/material.dart';
import 'dashboard_view.dart';

class SplashView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _showSplashView();
  }

  void _showSplashView() async{
    await Future.delayed(Duration(seconds: 3));
    if(mounted){
      setState(() => _pageIndex = 1);
      await Future.delayed(Duration(seconds: 3));
      if(mounted){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardView())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: AnimatedSwitcher(
        duration: (Duration(milliseconds: 500)),
        child: _pageIndex == 0 ? _firstPage() : _secondPage(),
      ),
    );
  }

  Widget _firstPage(){
    return Container(
      key: ValueKey<int>(0),
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/tutwurihandayani.png', width: 150, height: 150),
            SizedBox(height: 20),
            Text(
              'BALAI BAHASA\nPROVINSI JAWA BARAT',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'BADAN PENGEMBANGAN DAN PEMBINAAN BAHASA\nKEMENTERIAN PENDIDIKAN DASAR DAN MENENGAH',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondPage(){
    return Container(
      key: ValueKey<int>(1),
      color: Colors.white,
      child: Center(
        child: Image.asset(
          'assets/logo/hade.png',
          width: 180,
          height: 180,
        ),
      ),
    );
  }
}
