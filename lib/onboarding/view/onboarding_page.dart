import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/app_logo.dart';
import '../../widgets/illustration_slot.dart';
import '../../widgets/ink_button.dart';
import '../../widgets/screen_heading.dart';
import '../../widgets/text_link.dart';
import '../bloc/intro_bloc.dart';
import 'intro_slide.dart';
import 'widgets/balloon_dots.dart';

const _slides = [
  IntroSlide(
    eyebrow: 'Stuck somewhere awkward?',
    title: 'Need an easy way out?',
    body:
        'helpyy fakes a phone call so you can step away politely. '
        'No excuses, no awkward goodbyes.',
    caption: "we've all been there",
  ),
  IntroSlide(
    eyebrow: 'Step 1 · your secret signal',
    title: 'Tap the back of your phone.',
    body:
        'Save a signal, like 3 quick taps or your own knock rhythm. Keep '
        'helpyy open, and tap it on the back of your phone when you need out.',
    caption: 'tap, tap, tap',
  ),
  IntroSlide(
    eyebrow: 'Step 2 · right on cue',
    title: 'Your phone rings.',
    body:
        'A real looking call comes in from whoever you picked. Answer it, '
        'say "sorry, gotta take this", and walk away.',
    caption: 'gotta take this!',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finish() => context.read<IntroBloc>().add(const IntroFinished());

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: AppLogo()),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IllustrationSlot(caption: slide.caption),
                          const SizedBox(height: 20),
                          ScreenHeading(
                            eyebrow: slide.eyebrow,
                            title: slide.title,
                            body: slide.body,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    BalloonDots(controller: _pages, count: _slides.length),
                    const Spacer(),
                    if (!isLast) TextLink(label: 'Skip', onPressed: _finish),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkButton(
                label: switch (_index) {
                  0 => 'Show me how',
                  _ when isLast => 'Get started',
                  _ => 'Next',
                },
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
