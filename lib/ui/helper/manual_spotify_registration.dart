import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/ui/layout/editable_multiline_text.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';

class ManualSpotifyRegistration extends StatefulWidget {
  final String url;
  final Map<String, dynamic> translations;
  final void Function({required String url}) callbackUrl;

  const ManualSpotifyRegistration({
    super.key,
    required this.url,
    required this.translations,
    required this.callbackUrl,
  });

  @override
  State<ManualSpotifyRegistration> createState() =>
      ManualSpotifyRegistrationState();
}

class ManualSpotifyRegistrationState extends State<ManualSpotifyRegistration> {
  String get url => widget.url;
  Map<String, dynamic> get translations => widget.translations;
  void Function({required String url}) get callbackUrl => widget.callbackUrl;

  final TextEditingController textController = TextEditingController();
  String callbackFieldText = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorDefs.windowBackgroundColor(context: context),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Column(
          children: [
            EditableMultilineText(
              translations: translations,
              label:
                  (translations['callSpotifyUrlLabel'] ??
                      'Please enter the following URL into your web browser to log in to Spotify Connect') +
                  ':',
              maxLines: 6,
              readOnly: true,
              text: url,
              //onChanged: (value) {},
            ),
            SizedBox(height: 64.0),
            EditableMultilineText(
              translations: translations,
              withDebounce: false,
              label:
                  (translations['insertSpotifyCallbackUrlLabel'] ??
                      'Please enter the callback URL here, which will be displayed in your web browser after you successfully log in to Spotify Connect') +
                  ':',
              maxLines: 6,
              textController: textController,
              text: callbackFieldText,
              placeholder:
                  translations['insertSpotifyCallbackUrlPlaceholder'] ??
                  'Please enter the callback URL here',
              onChanged: (String value) {
                if (callbackFieldText != value) {
                  if (mounted) {
                    setState(() {
                      callbackFieldText = value;
                    });
                  }
                }
              },
            ),
            SizedBox(height: 64.0),
            IconTextButtonElement(
              onMacAsText: true,
              icon: Icon(Icons.check, size: 24, color: Colors.green),
              label:
                  translations['transmitSpotifyAuthCodeButtonLabel'] ??
                  'Send the authorization code to the device',
              onPressed:
                  callbackFieldText.isEmpty ||
                      !callbackFieldText.contains('/callback?code=')
                  ? null
                  : () {
                      callbackUrl(url: callbackFieldText);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
