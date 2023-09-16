import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedTitleDescription extends StatefulWidget {
  final String title;
  final String description;

  const AnimatedTitleDescription({super.key,
    required this.title,
    required this.description,
  });

  @override
  State<AnimatedTitleDescription> createState() =>
      _AnimatedTitleDescriptionState();
}

class _AnimatedTitleDescriptionState extends State<AnimatedTitleDescription> {
  bool _showDescription = false;
  bool _animationComplete = false;

  void _toggleDescription() {
    if (widget.description.isEmpty)return;
    setState(() {
      _animationComplete = false;
      _showDescription = !_showDescription;
    });
  }

  String getDesc() {
    if (widget.description.length > 300) {
      return "${widget.description.substring(0, 300)}...";
    }
    return widget.description;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: _showDescription ? 220 : 45,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width*0.921,
              height: _showDescription ? 220 : 45,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5)
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _toggleDescription,
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
               AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showDescription ? 160 : 0,
                  onEnd: () {
                    setState(() {
                      _animationComplete = _showDescription;
                    });
                  },
                  child: _animationComplete&&_showDescription
                      ? Column(
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(right: 28),
                        child: Text(
                          getDesc(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
