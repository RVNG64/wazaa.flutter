import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AdvertisementBanner extends StatefulWidget {
  const AdvertisementBanner({Key? key}) : super(key: key);

  @override
  _AdvertisementBannerState createState() => _AdvertisementBannerState();
}

class _AdvertisementBannerState extends State<AdvertisementBanner> {
  final List<Map<String, String>> ads = [
    {'image': 'lib/assets/images/adidas-ad.webp', 'url': 'https://www.adidas.fr'},
    {'image': 'lib/assets/images/adidas-ad2.jpg', 'url': 'https://www.adidas.fr'},
    {'image': 'lib/assets/images/airfrance-ad.webp', 'url': 'https://www.airfrance.com'},
    {'image': 'lib/assets/images/appletv-ad.jpg', 'url': 'https://tv.apple.com'},
    {'image': 'lib/assets/images/backmarket-ad.png', 'url': 'https://www.backmarket.com'},
    {'image': 'lib/assets/images/dune2-ad.jpg', 'url': 'https://www.dune.com'},
    {'image': 'lib/assets/images/nike-ad1.jpg', 'url': 'https://www.nike.fr'},
    {'image': 'lib/assets/images/nike-ad2.jpg', 'url': 'https://www.nike.fr'},
    {'image': 'lib/assets/images/nikeskate-ad.webp', 'url': 'https://www.nike.com/fr/skateboard'},
    {'image': 'lib/assets/images/sony-ad.jpg', 'url': 'https://www.sony.fr'},
  ];

  int _currentAdIndex = 0;
  Timer? _adTimer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startAdRotation();
  }

  void _startAdRotation() {
    _adTimer = Timer.periodic(Duration(seconds: 10), (Timer timer) {
      if (mounted) {
        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % ads.length;
          _pageController.animateToPage(
            _currentAdIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel(); // Annuler le timer lors de la destruction du widget
    _pageController.dispose();
    super.dispose();
  }

  void _launchURL(String url) async {
    // Utilisez le mode platformDefault pour laisser le système choisir l'application par défaut
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.platformDefault);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        String adUrl = ads[_currentAdIndex]['url']!;
        _launchURL(adUrl); // Ouvrir le lien associé à la publicité
      },
      child: Container(
        width: double.infinity,
        height: 130, // Hauteur de la bannière publicitaire
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentAdIndex = index;
            });
          },
          itemCount: ads.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _launchURL(ads[index]['url']!); // Lancer l'URL quand l'image est cliquée
              },
              child: Material(
                elevation: 8, // Élève l'élément pour donner un effet de relief
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3), // Pour rendre l'ombre plus naturelle
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    child: Image.asset(
                      ads[index]['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Text('Erreur de chargement de l\'image'));
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
