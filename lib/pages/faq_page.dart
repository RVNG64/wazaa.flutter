import 'package:flutter/material.dart';
import './contact_page.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond en dégradé radial
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF205893), // Bleu très foncé en haut
                  Color(0xFF16141E), // Bleu moyen en bas
                ],
              ),
            ),
          ),
          // Contenu principal
          Column(
            children: [
              // Bouton de fermeture en haut à gauche
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 50),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Fermer la FAQ
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'FAQ',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Liste des questions
              const Expanded(
                child: FAQList(), // Utilisation du widget séparé pour la liste des FAQ
              ),
              // Bouton en bas de page
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity, // Le bouton occupe toute la largeur
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Contactez-nous',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget séparé pour la liste des FAQ pour simplifier la gestion des questions
class FAQList extends StatelessWidget {
  const FAQList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final faqItems = [
      const FAQItem(
        question: 'Quel est le principe de WAZAA ?',
        answer: "WAZAA est une plateforme innovante qui vous permet de découvrir des événements locaux près de chez vous, publics ou privés.",
      ),
      const FAQItem(
        question: 'Je trouve des événements uniquement dans le Sud-Ouest, pourquoi ?',
        answer: "Ce n'est que le début ! Nous étendrons bientôt notre couverture à d'autres régions. Restez à l'écoute !",
      ),
      const FAQItem(
        question: 'Comment ajouter un événement ?',
        answer: "Vous pourrez bientôt le faire directement depuis l\'application! En attendant, contactez-nous via le bouton ci-dessous ou via hello@wazaa.app.",
      ),
      const FAQItem(
        question: 'Sera-t-il possible d\'ajouter des amis, partager des événements et chatter ?',
        answer: 'Oui, ces fonctionnalités sont prévues dans les prochaines mises à jour. Restez connectés !',
      ),
      const FAQItem(
        question: 'Quelles sont les futures fonctionnalités prévues ?',
        answer: 'Les prochaines mises à jour incluront la possibilité de créer des événements depuis l\'application, de partager des événements, d\'ajouter des amis et chatter avec eux.',
      ),
    ];

    return ListView.builder(
      itemCount: faqItems.length,
      itemBuilder: (context, index) {
        return faqItems[index];
      },
    );
  }
}

// Composant FAQItem avec une ExpansionTile pour les questions et réponses
class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const FAQItem({
    Key? key,
    required this.question,
    required this.answer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Text(
          question,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
