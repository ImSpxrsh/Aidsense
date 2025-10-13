import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  List<Map<String, String>> pages = [
    {
      'title': 'Enter Your Location',
      'subtitle': 'Find nearby community resources easily.',
      'image': 'assets/images/onboarding_new.svg'
    },
    {
      'title': 'Find Resources Easily',
      'subtitle': 'Search and filter to find what you need.',
      'image': 'assets/images/Onboardingscreenimage2.png'
    },
    {
      'title': 'Join Your Community',
      'subtitle': 'Connect and share with local groups.',
      'image': 'assets/images/Onboardingscreenimage3.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0, bottom: 6.0),
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Skip',
                  style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 14, color: primary),
            ]),
          ),
        )
      ]),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // enlarge images to better match the design
                      Image.asset(
                        pages[i]['image']!,
                        height: MediaQuery.of(context).size.height * 0.38,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        pages[i]['title']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB71C1C), // darker red
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pages[i]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // pagination indicators
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.all(6),
                  width: _page == index ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == index ? primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              })),

          // bottom area with decorative half-oval behind the button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: SizedBox(
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // decorative half-oval (top-rounded only so it reads like a half-oval)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 320,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(200, 210, 220, 0.12),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(80)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 26,
                    child: Center(
                      child: SizedBox(
                        width: 240,
                        height: 62,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_page < pages.length - 1) {
                              _pc.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            } else {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            minimumSize: const Size.fromHeight(56),
                          ),
                          child: Text(
                              _page < pages.length - 1 ? 'Next' : 'Get Started',
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
