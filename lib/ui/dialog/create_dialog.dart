import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'dart:io';

import '../../utils/models/post_model.dart';

class CreatePostDialog extends StatefulWidget {
  final Function(Post,File?) onSave;

  const CreatePostDialog({super.key, required this.onSave});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? imageFile;

  Widget buildImagePost() {
    return Column(
      children: [
        imageFile != null? AspectRatio(
          aspectRatio: 4/3,
          child: Image.file(
            File(imageFile!.path,),
            fit: BoxFit.cover,
          ),
        )
        :
        TextButton(
            onPressed: () async {
              ImagePickerPlus picker = ImagePickerPlus(context);

              SelectedImagesDetails? details =
              await picker.pickImage(source: ImageSource.gallery);
              if (details == null || details.selectedFiles.isEmpty) return;
              setState(() {
                imageFile = details.selectedFiles[0].selectedFile;
              });
            },
            child: Container(
              width: 170,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(FontAwesomeIcons.image),
                  Text('Pick an image'),
                ],
              ),
            ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _captionController,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Caption',
            hintText: 'Enter a caption',
            icon: Icon(FontAwesomeIcons.font),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(8.0),
          ),
        ),
        TextField(
          controller: _descriptionController,
          maxLength: 300,
          maxLines: 6,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter a description',
            icon: Icon(FontAwesomeIcons.quoteLeft),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(8.0),
          ),
        ),
        const SizedBox(height: 10),
        buildPostRow(),
      ],
    );
  }


  Row buildPostRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            String uploaderId = '';
            String caption = _captionController.text;
            String description = _descriptionController.text;

            if (caption.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a caption'),
                ),
              );
              return;
            }

            Post post = Post(
              id: '',
              uploaderId: uploaderId,
              caption: caption,
              description: description,
              image: null,
            );

            widget.onSave(post,imageFile);
            Navigator.of(context).pop();
          },
          child: const SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(FontAwesomeIcons.circlePlus),
                Text('Create post'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: 600,
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Create a Post',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    buildImagePost(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
