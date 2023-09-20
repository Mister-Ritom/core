import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimatedHeartButton extends StatefulWidget {
  final String postId;
  final bool isLiked;
  final int count;
  final int width;

  const AnimatedHeartButton(
      {super.key,
      required this.count,
      required this.postId,
      required this.isLiked,
        int? width
      }
  ): width = width ?? 100;

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _liked = false;
  int likes = 0;

  @override
  void initState() {
    setState(() {
      _liked = widget.isLiked;
      likes = widget.count;
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> setLikeDatabase() async {
    final likesCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
        .collection("likes");
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (!_liked) {
      final id = UniqueKey().toString();
      await likesCol.doc(currentUserId).set({
        "timestamp": DateTime.now(),
        "actionId": id,
      });
    } else {
      await likesCol.doc(currentUserId).delete();
    }
  }

  void _handleTap() async {
    await setLikeDatabase();
    setState(() {
      _liked = !_liked;
      if (_liked) {
        _controller.forward();
        likes++;
      } else {
        _controller.reverse();
        likes--;
      }
    });
  }

  List<Widget> getChildren() {
    return [
      AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: RotationTransition(
              turns: _controller,
              child: Icon(
                _liked
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                color: _liked
                    ? Colors.red
                    : Theme.of(context).colorScheme.inverseSurface,
                size: 16,
              ),
            ),
          );
        },
      ),
      if (widget.width>90)
      const Padding(
        padding: EdgeInsets.all(2.0),
        child: Icon(
          FontAwesomeIcons.solidCircle,
          size: 5.0,
        ),
      ),
      Text(
        "$likes likes",
        style: TextStyle(
          color: _liked
              ? Colors.red
              : Theme.of(context).colorScheme.inverseSurface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: widget.width>90? Row(
        children:getChildren(),
      ) : Column(
        children: getChildren(),
      ),
    );
  }
}
