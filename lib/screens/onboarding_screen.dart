import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  List<Map<String,String>> pages = [
    {'title':'Enter Your Location','subtitle':'Find nearby community resources easily.'},
    {'title':'Find Resources Easily','subtitle':'Search and filter to find what you need.'},
    {'title':'Join Your Community','subtitle':'Connect and share with local groups.'},
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFFF48A8A);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: [
        TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: Text('Skip', style: TextStyle(color: primary)))
      ]),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: pages.length,
              onPageChanged: (i) => setState(()=>_page = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal:20, vertical:8),
                  child: Column(
                    children: [
                      SizedBox(height:8),
                      Image.asset('assets/images/onboarding_strip.png', height:240, fit: BoxFit.contain),
                      SizedBox(height:18),
                      Text(pages[i]['title']!, style: TextStyle(fontSize:22, fontWeight: FontWeight.bold, color: primary)),
                      SizedBox(height:8),
                      Text(pages[i]['subtitle']!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pages.length, (index){
            return Container(margin: EdgeInsets.all(6), width: _page==index?14:8, height: 8, decoration: BoxDecoration(color: _page==index?primary:Colors.grey[300], borderRadius: BorderRadius.circular(8)));
          })),
          Padding(
            padding: EdgeInsets.symmetric(horizontal:24.0, vertical:20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (){
                  if(_page < pages.length-1) {
                    _pc.nextPage(duration: Duration(milliseconds:300), curve: Curves.easeInOut);
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primary, shape: StadiumBorder(), padding: EdgeInsets.symmetric(vertical:14)),
                child: Text(_page < pages.length-1 ? 'Next' : 'Continue to Login', style: TextStyle(fontSize:16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}